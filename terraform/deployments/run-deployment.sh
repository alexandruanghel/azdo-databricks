#!/usr/bin/env bash
#
# Runs a deployment using the output from the admin setup.
# It extracts from the Terraform output the Azure remote backend details and variables for the provisioned resources.
# For this to work, it must be run on the same machine as the admin setup.
#

# Debug
#set -x
#export TF_LOG="DEBUG"

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_this_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_scripts_dir=${_this_script_dir}/../../scripts
_python="$(command -v python || command -v python3)"

# Prepare variables
## extract variables from terraform admin output
echo -e "Extracting variables from terraform admin output"
tf_admin_output=$(terraform output -json -state "${_this_script_dir}/../../admin/terraform/terraform.tfstate")
if [ -z "${tf_admin_output}" ] || [ "${tf_admin_output}" == "{}" ]; then
  echo -e "Could not extract the required variables from the admin setup state (\"${_this_script_dir}/../../admin/terraform/terraform.tfstate\")"
  echo -e "\"${_this_script_dir}/../../admin/setup-with-terraform.sh\" must be run first"
  exit 1
fi

## for the remote azurerm backend
export TF_RESOURCE_GROUP_NAME=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["terraform_resources"]["value"]["resource_group_name"])')
export TF_STORAGE_ACCOUNT_NAME=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["terraform_resources"]["value"]["terraform_storage_account_name"])')
export TF_CONTAINER_NAME=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["terraform_resources"]["value"]["terraform_storage_container_name"])')
export TF_KEY="tftest-$(basename "${1}").tfstate"

## for the already provisioned resources
export TF_VAR_DATA_SERVICE_PRINCIPAL_CLIENT_ID=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["databricks_resources"]["value"]["data_service_principal_application_id"])')
export TF_VAR_PROJECT_GROUP_NAME=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["databricks_resources"]["value"]["project_group_name"])')
export TF_VAR_RESOURCE_GROUP_NAME=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["databricks_resources"]["value"]["resource_group_name"])')
export TF_VAR_KEY_VAULT_NAME=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["databricks_resources"]["value"]["key_vault_name"])')
export TF_VAR_SECRET_NAME_CLIENT_SECRET=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["databricks_resources"]["value"]["secret_name"])')
export ARM_CLIENT_ID=$(echo "${tf_admin_output}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["databricks_resources"]["value"]["infra_service_principal_application_id"])')

## add uniqueness to the storage account as a workaround for https://github.com/terraform-providers/terraform-provider-azurerm/issues/10872
suffix=$(echo "${ARM_CLIENT_ID}" | cut -c 1-3)
STORAGE_ACCOUNT_NAME="$(grep STORAGE_ACCOUNT_NAME test.tfvars | cut -d'=' -f2 | cut -d'"' -f2)${suffix}"
[ -z "${STORAGE_ACCOUNT_NAME}" ] && exit 1

# Generate a new client secret for the infra Service Principal to simulate the Azure DevOps environment
echo -e "Generating a new client secret for the infra Service Principal"
ARM_CLIENT_SECRET=$(az ad sp credential reset --name "${ARM_CLIENT_ID}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["password"])')
[ -z "${ARM_CLIENT_SECRET}" ] && exit 1
export ARM_CLIENT_SECRET

ARM_TENANT_ID=$(az account show | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["tenantId"])')
[ -z "${ARM_TENANT_ID}" ] && exit 1
export ARM_TENANT_ID

ARM_SUBSCRIPTION_ID=$(az account show | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)
[ -z "${ARM_SUBSCRIPTION_ID}" ] && exit 1
export ARM_SUBSCRIPTION_ID

# Wait until the secret is active
echo -e "Sleeping for 10 minutes to allow enough time for the client secret to propagate" && sleep 600

# Run test
echo -e "Running the test"
source "${_scripts_dir}/terraform_azure.sh" apply "$@" -var-file="${_this_script_dir}/test.tfvars" -var="STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}" -auto-approve
echo
