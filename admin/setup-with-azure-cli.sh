#!/usr/bin/env bash
#
# Builds the core infrastructure using Azure CLI and scripts.
# Variables are loaded from the vars.sh file.
# Only users can run this script as granting admin-consent with a Service Principal is not supported by the az ad cli.
# The user executing this script must be Owner on the Subscription and Global administrator on the AD Tenant.
#

# Debug
#set -x


### Variables

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_setup_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_scripts_dir=${_setup_script_dir}/../scripts
_python="$(command -v python || command -v python3)"

# Import variables
source "${_setup_script_dir}/vars.sh"

# Required variables
## the Personal Access Token to authenticate to GitHub
AZURE_DEVOPS_EXT_GITHUB_PAT=${AZURE_DEVOPS_EXT_GITHUB_PAT:-${AZDO_GITHUB_SERVICE_CONNECTION_PAT}}

## the Azure DevOps organization url
AZURE_DEVOPS_ORG_URL=${AZURE_DEVOPS_ORG_URL:-${AZDO_ORG_SERVICE_URL}}

# Optional variables
## will use azure cli login if the PAT is not defined
AZURE_DEVOPS_EXT_PAT=${AZURE_DEVOPS_EXT_PAT:-${AZDO_PERSONAL_ACCESS_TOKEN}}

## set the infra pipeline path to the correct yaml file
AZURE_DEVOPS_INFRA_PIPELINE_PATH=${AZURE_DEVOPS_INFRA_PIPELINE_PATH:-${AZURE_DEVOPS_INFRA_PIPELINE_PATH_CLI}}

# Check the required variables
if [ -z "${AZURE_DEVOPS_EXT_GITHUB_PAT}" ]; then
  echo "ERROR: The GitHub PAT token was not defined"
  echo "       Either AZURE_DEVOPS_EXT_GITHUB_PAT or AZDO_GITHUB_SERVICE_CONNECTION_PAT variables must be set"
  exit 1
else
  export AZURE_DEVOPS_EXT_GITHUB_PAT
fi
if [ -z "${AZURE_DEVOPS_ORG_URL}" ]; then
  echo "ERROR: The Azure DevOps organization URL was not defined"
  echo "       Either AZURE_DEVOPS_ORG_URL or AZDO_ORG_SERVICE_URL variables must be set"
  exit 1
else
  export AZURE_DEVOPS_ORG_URL
  export AZURE_DEVOPS_EXT_PAT
fi


### Core Azure resources

echo -e "Building the core Azure resources\n----------------------------------------------"
echo

# Check the required Azure RM parameters
echo -e "Checking the Azure RM parameters\n----------------------"
if [ -z "${AZURE_LOCATION}" ] || [ -z "${INFRA_SP_NAME}" ] || [ -z "${DATA_SP_NAME}" ] || \
   [ -z "${DATABRICKS_RESOURCE_GROUP_NAME}" ] || [ -z "${KEY_VAULT_NAME}" ] || [ -z "${SECRET_NAME}" ]; then
  echo "ERROR: One or more of the following variables was not defined: AZURE_LOCATION, INFRA_SP_NAME, DATA_SP_NAME,"
  echo "       DATABRICKS_RESOURCE_GROUP_NAME, KEY_VAULT_NAME, SECRET_NAME"
  echo "       These variables must be set for the basic Azure setup"
  exit 1
fi

echo -e "Parameters set. Creating the following Azure resources in \"${AZURE_LOCATION}\":
* Azure Service Principal for infrastructure deployment: \"${INFRA_SP_NAME}\"
* Azure Service Principal for data pipeline: \"${DATA_SP_NAME}\"
* Databricks Resource Group: \"${DATABRICKS_RESOURCE_GROUP_NAME}\"
* Azure Key Vault: \"${KEY_VAULT_NAME}\"
* Azure Key Vault Secret: \"${SECRET_NAME}\"
"

# Make sure the current Azure CLI login works (using a Service Principal is not supported for this)
echo -e "Checking the existing Azure Authentication\n----------------------"
az_account=$(az account show)
[ -z "${az_account}" ] && exit 1
user_type=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["user"]["type"])')
user_name=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["user"]["name"])')
[ -z "${user_type}" ] || [ -z "${user_name}" ] && exit 1
if [ "${user_type}" == "servicePrincipal" ]; then
  echo -e "ERROR: Authenticating using the Azure CLI as a User is required for this setup."
  echo -e "       Granting admin-consent with a Service Principal is not supported by the az ad cli."
  echo -e "       This is due to https://github.com/Azure/azure-cli/issues/12137."
  echo -e "       Please run 'az login' with a directory administrator User Principal."
  exit 1
else
  echo -e "Will use the current Azure CLI login (\"${user_name}\") to authenticate to Azure RM"
fi

# Set the Subscription
if [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
  echo -e "Setting the active subscription to \"${ARM_SUBSCRIPTION_ID}\""
  az account set --subscription "${ARM_SUBSCRIPTION_ID}" || exit 1
fi
echo

# Make sure all of the required Resource Provider are registered in the Subscription
echo -e "Registering the required providers\n----------------------"
providers="
Microsoft.Compute
Microsoft.Storage
Microsoft.DataLakeStore
Microsoft.Network
Microsoft.KeyVault
Microsoft.ManagedIdentity
Microsoft.Databricks
Microsoft.DataFactory
Microsoft.DBforMySQL
Microsoft.Sql
"

for provider in ${providers}; do
  echo -e "Registering the \"${provider}\" provider"
  az provider register --namespace "${provider}" --wait || exit 1
done
echo

# Create the Azure Service Principal to be used for infrastructure deployment
echo -e "Creating the Azure Service Principal \"${INFRA_SP_NAME}\" to be used for infrastructure deployment\n----------------------"
source "${_scripts_dir}/create_service_principal.sh" "${INFRA_SP_NAME}"
infra_sp_client_id=${sp_client_id}
infra_sp_client_secret=${sp_client_secret}
echo

# Create the Azure Service Principal to be used by the data pipeline
echo -e "Creating the Azure Service Principal \"${DATA_SP_NAME}\" to be used by the data pipeline\n----------------------"
source "${_scripts_dir}/create_service_principal.sh" "${DATA_SP_NAME}"
data_sp_client_id=${sp_client_id}
data_sp_client_secret=${sp_client_secret}
echo

# Create the Azure Project group
echo -e "Creating the Azure Project group \"${PROJECT_GROUP_NAME}\"\n----------------------"
az ad group show --group "${PROJECT_GROUP_NAME}" > /dev/null \
  || az ad group create --display-name "${PROJECT_GROUP_NAME}" --mail-nickname "$(echo "${PROJECT_GROUP_NAME}" | tr -d '[:blank:]')" > /dev/null || exit 1
echo -e "Project \"${PROJECT_GROUP_NAME}\" created"
echo

# Create the Databricks resource group
echo -e "Creating the Resource Group \"${DATABRICKS_RESOURCE_GROUP_NAME}\" for Databricks use\n----------------------"
_response=$(az group create --name "${DATABRICKS_RESOURCE_GROUP_NAME}" --location "${AZURE_LOCATION}")
[ -z "${_response}" ] && exit 1
echo -e "Resource Group \"${DATABRICKS_RESOURCE_GROUP_NAME}\" created"
echo

# Create the Azure Key Vault
echo -e "Creating the Azure Key Vault \"${KEY_VAULT_NAME}\"\n----------------------"
_response=$(az keyvault show --resource-group "${DATABRICKS_RESOURCE_GROUP_NAME}" --name "${KEY_VAULT_NAME}" 2>/dev/null \
              || az keyvault create --resource-group "${DATABRICKS_RESOURCE_GROUP_NAME}" --name "${KEY_VAULT_NAME}")
[ -z "${_response}" ] && exit 1
echo -e "Azure Key Vault \"${KEY_VAULT_NAME}\" created"
echo

# Add the data pipeline Service Principal secret to the Key Vault
echo -e "Storing the data pipeline Service Principal secret in Key Vault \"${KEY_VAULT_NAME}\"\n----------------------"
source "${_scripts_dir}/add_secret_to_key_vault.sh" "${KEY_VAULT_NAME}" "${SECRET_NAME}" "${data_sp_client_secret}" "2" "${data_sp_client_id}"
echo

## Assign the "Directory.Read.All" API Permissions in Azure Active Directory Graph
echo -e "Assigning \"Directory.Read.All\" API Permission in Azure Active Directory Graph to \"${INFRA_SP_NAME}\"\n----------------------"
source "${_scripts_dir}/add_api_permission.sh" "ad" "Directory.Read.All" "${infra_sp_client_id}"
echo

# Assign the Owner role on the Databricks resource group
echo -e "Assigning the Owner role on the Databricks Resource Group to \"${INFRA_SP_NAME}\"\n----------------------"
source "${_scripts_dir}/add_role_assignment.sh" "Owner" "${infra_sp_client_id}" "${DATABRICKS_RESOURCE_GROUP_NAME}"
echo


### Azure DevOps Project
echo
echo -e "Building the Azure DevOps Project\n----------------------------------------------"
echo

# Check the required Azure DevOps parameters
echo -e "Checking the Azure DevOps parameters\n----------------------"
if [ -z "${AZURE_DEVOPS_ORG_URL}" ] || [ -z "${AZURE_DEVOPS_PROJECT_NAME}" ] || [ -z "${AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME}" ] || \
   [ -z "${AZURE_DEVOPS_GITHUB_ENDPOINT_NAME}" ] || [ -z "${AZURE_DEVOPS_GITHUB_REPO_URL}" ] || [ -z "${AZURE_DEVOPS_GITHUB_BRANCH}" ] || \
   [ -z "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" ] || [ -z "${AZURE_DEVOPS_INFRA_PIPELINE_PATH}" ]; then
  echo "ERROR: One or more of the following variables was not defined: AZURE_DEVOPS_ORG_URL, AZURE_DEVOPS_PROJECT_NAME,"
  echo "       AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME, AZURE_DEVOPS_GITHUB_ENDPOINT_NAME, AZURE_DEVOPS_GITHUB_REPO_URL,"
  echo "       AZURE_DEVOPS_GITHUB_BRANCH, AZURE_DEVOPS_INFRA_PIPELINE_NAME, AZURE_DEVOPS_INFRA_PIPELINE_PATH"
  echo "       These variables must be set for the Azure DevOps setup"
  exit 1
fi

# When the Azure DevOps PAT is defined, also export the required subscription details
if [ -n "${AZURE_DEVOPS_EXT_PAT}" ]; then
  az_account=$(az account show)
  [ -z "${az_account}" ] && exit 1
  ARM_TENANT_ID=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["tenantId"])')
  ARM_SUBSCRIPTION_ID=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])')
  ARM_SUBSCRIPTION_NAME=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["name"])')
  export ARM_TENANT_ID
  export ARM_SUBSCRIPTION_ID
  export ARM_SUBSCRIPTION_NAME
fi

echo -e "Parameters set. Creating the following Azure DevOps resources in the \"${AZURE_DEVOPS_ORG_URL}\" Organization:
* Project: \"${AZURE_DEVOPS_PROJECT_NAME}\"
* Azure RM infra service endpoint: \"${AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME}\"
* Azure RM data service endpoint: \"${AZURE_DEVOPS_DATA_ARM_ENDPOINT_NAME}\"
* GitHub service endpoint: \"${AZURE_DEVOPS_GITHUB_ENDPOINT_NAME}\" (to the repo \"${AZURE_DEVOPS_GITHUB_REPO_URL}\" and the \"${AZURE_DEVOPS_GITHUB_BRANCH}\" branch)
* Pipeline: \"${AZURE_DEVOPS_INFRA_PIPELINE_NAME}\" (from YAML file path \"${AZURE_DEVOPS_INFRA_PIPELINE_PATH}\")
"

# Create the Azure DevOps project
source "${_scripts_dir}/azdo_project.sh" create "${AZURE_DEVOPS_PROJECT_NAME}"
echo

# Create a GitHub type service endpoint
source "${_scripts_dir}/azdo_github_endpoint.sh" create "${AZURE_DEVOPS_GITHUB_ENDPOINT_NAME}"
echo

# Set variables required by the Azure DevOps integration (for the infra Service Principal)
export ARM_CLIENT_ID=${infra_sp_client_id}
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=${infra_sp_client_secret}

# Create an Azure RM type service endpoint to be used by the infra pipeline
source "${_scripts_dir}/azdo_arm_endpoint.sh" create "${AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME}"
echo

# Set variables required by the Azure DevOps integration (for the data pipeline Service Principal)
export ARM_CLIENT_ID=${data_sp_client_id}
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=${data_sp_client_secret}

# Create an Azure RM type service endpoint to be used by the data pipeline
source "${_scripts_dir}/azdo_arm_endpoint.sh" create "${AZURE_DEVOPS_DATA_ARM_ENDPOINT_NAME}"
echo

# Create the Azure Pipeline for infrastructure deployment
source "${_scripts_dir}/azdo_pipeline.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" "${AZURE_DEVOPS_INFRA_PIPELINE_PATH}"
echo

# Add variables to the infra pipeline
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" serviceConnection "${AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" provisionedServicePrincipalClientId "${data_sp_client_id}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" provisionedProjectGroupName "${PROJECT_GROUP_NAME}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" provisionedResourceGroupName "${DATABRICKS_RESOURCE_GROUP_NAME}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" provisionedKeyVaultName "${KEY_VAULT_NAME}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" provisionedSecretName "${SECRET_NAME}"
echo


# Create the Azure Pipeline for the Azure Data Factory data pipeline
source "${_scripts_dir}/azdo_pipeline.sh" create "${AZURE_DEVOPS_DATA_PIPELINE_NAME}" "${AZURE_DEVOPS_DATA_PIPELINE_PATH}"
echo

# Add variables to the data pipeline
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_DATA_PIPELINE_NAME}" serviceConnection "${AZURE_DEVOPS_DATA_ARM_ENDPOINT_NAME}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_DATA_PIPELINE_NAME}" provisionedResourceGroupName "${DATABRICKS_RESOURCE_GROUP_NAME}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_DATA_PIPELINE_NAME}" provisionedKeyVaultName "${KEY_VAULT_NAME}"
echo
source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_DATA_PIPELINE_NAME}" provisionedSecretName "${SECRET_NAME}"
echo

# Install the Microsoft DevLabs Databricks extension for Azure DevOps
source "${_scripts_dir}/azdo_extension.sh" install "azdo-databricks" "riserrad"


### Azure infrastructure for Terraform

if [ -n "${TF_RESOURCE_GROUP_NAME}" ] && [ -n "${TF_STORAGE_ACCOUNT_NAME}" ] && [ -n "${TF_CONTAINER_NAME}" ] && \
  { [ -z "${USE_TERRAFORM}" ] || [ "${USE_TERRAFORM}" = "yes" ] || [ "${USE_TERRAFORM}" = "true" ]; }; then
  echo -e "Building the Azure resources for Terraform state\n----------------------------------------------"
  echo
  echo -e "Creating the following Azure resources in \"${AZURE_LOCATION}\":
  * Terraform resource group: \"${TF_RESOURCE_GROUP_NAME}\" (with \"${INFRA_SP_NAME}\" as Contributor)
  * Terraform storage account: \"${TF_STORAGE_ACCOUNT_NAME}\"
  * Terraform storage container for storing state: \"${TF_CONTAINER_NAME}\"
  "

  # Install the Terraform extension for Azure DevOps
  source "${_scripts_dir}/azdo_extension.sh" install "custom-terraform-tasks" "ms-devlabs"

  # Create the Terraform resource group
  echo -e "Creating the Resource Group \"${TF_RESOURCE_GROUP_NAME}\" for Terraform use\n----------------------"
  _response=$(az group create --name "${TF_RESOURCE_GROUP_NAME}" --location "${AZURE_LOCATION}")
  [ -z "${_response}" ] && exit 1
  echo -e "Resource Group \"${TF_RESOURCE_GROUP_NAME}\" created"
  echo

  # Create the Terraform storage account
  echo -e "Creating the Storage Account \"${TF_STORAGE_ACCOUNT_NAME}\" for Terraform use\n----------------------"
  tf_storage_account_id=$(az storage account show --resource-group "${TF_RESOURCE_GROUP_NAME}" \
                                                  --name "${TF_STORAGE_ACCOUNT_NAME}" \
                           | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)

  if [ -z "${tf_storage_account_id}" ] && ! az storage account create \
                                                      --resource-group "${TF_RESOURCE_GROUP_NAME}" \
                                                      --location "${TF_AZURE_LOCATION}" \
                                                      --name "${TF_STORAGE_ACCOUNT_NAME}" \
                                                      --sku Standard_LRS \
                                                      --encryption-services blob > /dev/null; then
    echo -e "ERROR: Storage Account \"${TF_STORAGE_ACCOUNT_NAME}\" was not created successfully"
    exit 1
  else
    tf_storage_account_id=$(az storage account show --resource-group "${TF_RESOURCE_GROUP_NAME}" \
                                                    --name "${TF_STORAGE_ACCOUNT_NAME}" \
                             | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)
    [ -z "${tf_storage_account_id}" ] && { echo -e "ERROR: Storage Account \"${TF_STORAGE_ACCOUNT_NAME}\" was not created successfully"; exit 1; }
    echo -e "Storage Account \"${TF_STORAGE_ACCOUNT_NAME}\" created successfully"
  fi
  echo

  # Create the Terraform state blob container
  echo -e "Creating the Storage Container \"${TF_CONTAINER_NAME}\" for Terraform use\n----------------------"
  timer=0
  while [ ${timer} -lt 100 ]; do
    az storage container create --auth-mode login \
                                --account-name "${TF_STORAGE_ACCOUNT_NAME}" \
                                --name "${TF_CONTAINER_NAME}" > /dev/null && break
    echo -e "Storage Account \"${TF_STORAGE_ACCOUNT_NAME}\" might not be accessible yet, sleeping for 10 seconds"
    sleep 10 && timer=$((timer+10)) && (exit 1)
  done || { echo "ERROR: Timed out waiting"; exit 1; }
  echo -e "Storage Container \"${TF_CONTAINER_NAME}\" created successfully"
  echo

  # Assign the Owner role on the Terraform Resource Group
  echo -e "Assigning the required roles on the Terraform resources to \"${INFRA_SP_NAME}\"\n----------------------"
  source "${_scripts_dir}/add_role_assignment.sh" "Owner" "${infra_sp_client_id}" "${TF_RESOURCE_GROUP_NAME}"
  echo

  # Assign the Storage Blob Data Contributor role on the Storage Account
  source "${_scripts_dir}/add_role_assignment.sh" "Storage Blob Data Contributor" "${infra_sp_client_id}" "${tf_storage_account_id}"
  echo

  # Add Terraform variables to the pipeline
  source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" tfResourceGroupName "${TF_RESOURCE_GROUP_NAME}"
  echo
  source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" tfStorageAccountName "${TF_STORAGE_ACCOUNT_NAME}"
  echo
  source "${_scripts_dir}/azdo_pipeline_variable.sh" create "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" tfContainerName "${TF_CONTAINER_NAME}"
  echo

  # Print Terraform variables to use
  echo -e "Backend configuration to use:\n---------------------------------"
  echo "
  terraform {
    backend \"azurerm\" {
      resource_group_name  = \"${TF_RESOURCE_GROUP_NAME}\"
      storage_account_name = \"${TF_STORAGE_ACCOUNT_NAME}\"
      container_name       = \"${TF_CONTAINER_NAME}\"
      key                  = \"terraform.tfstate\"
    }
  }
  "

  echo -e "terraform init command to run:\n---------------------------------"
  echo "
  terraform init \\
    -backend-config=\"resource_group_name=${TF_RESOURCE_GROUP_NAME}\" \\
    -backend-config=\"storage_account_name=${TF_STORAGE_ACCOUNT_NAME}\" \\
    -backend-config=\"container_name=${TF_CONTAINER_NAME}\" \\
    -backend-config=\"key=terraform.tfstate\"
  "
fi
