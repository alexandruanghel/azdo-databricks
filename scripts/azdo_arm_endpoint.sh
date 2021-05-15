#!/usr/bin/env bash
#
# Manages an Azure DevOps Azure RM service endpoint (using https://docs.microsoft.com/en-us/cli/azure/devops/service-endpoint/azurerm).
# It uses both positional arguments and environment variables.
#

# Debug
#set -x

# Local variables
_python="$(command -v python || command -v python3)"

# Environment variables
export AZURE_DEVOPS_ORG_URL=${AZURE_DEVOPS_ORG_URL:-${AZDO_ORG_SERVICE_URL}}
export AZURE_DEVOPS_EXT_PAT=${AZURE_DEVOPS_EXT_PAT:-${AZDO_PERSONAL_ACCESS_TOKEN}}
export AZURE_DEVOPS_PROJECT_NAME=${AZURE_DEVOPS_PROJECT_NAME:-}

# Azure RM service endpoint variables
export ARM_CLIENT_ID=${ARM_CLIENT_ID:-}
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=${AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY:-${ARM_CLIENT_SECRET}}


_usage() {
  echo -e "Usage: ${0} {create|delete} <endpoint_name>"
  exit 1
}

_install_extension() {
  # Install the Azure DevOps cli extension
  az extension add --name azure-devops 2> /dev/null || { az extension add --name azure-devops --debug; exit 1; }
}

_check_args() {
  # Check the input parameters
  [ -z "${2}" ] && _usage
  if [ -z "${AZURE_DEVOPS_ORG_URL}" ]; then
    echo "ERROR: The Azure DevOps organization URL was not defined"
    echo "       Either AZURE_DEVOPS_ORG_URL or AZDO_ORG_SERVICE_URL variables must be set"
    exit 1
  fi
  if [ -z "${AZURE_DEVOPS_PROJECT_NAME}" ]; then
    echo "ERROR: The Azure DevOps Project name was not defined"
    echo "       The AZURE_DEVOPS_PROJECT_NAME variable must be set"
    exit 1
  fi
}

_check_auth() {
  # Check the existing Azure Authentication
  if [ -n "${AZURE_DEVOPS_EXT_PAT}" ]; then
    if [ -z "${ARM_TENANT_ID}" ] || [ -z "${ARM_SUBSCRIPTION_ID}" ] || [ -z "${ARM_SUBSCRIPTION_NAME}" ]; then
      echo "ERROR: Either AZURE_DEVOPS_EXT_PAT or AZDO_PERSONAL_ACCESS_TOKEN was set but the Azure RM variables were not"
      echo "       When using an Azure DevOps Personal Access Token, the following environment variables"
      echo "       must also be defined: ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_SUBSCRIPTION_NAME"
      exit 1      
    fi
  else
    az_signed_in_user=$(az ad signed-in-user show 2> /dev/null | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["userPrincipalName"])' 2> /dev/null)
    if [ -z "${az_signed_in_user}" ]; then
      echo "ERROR: User Principal not logged in, run 'az login' first (az login with a Service Principal is not supported)"
      echo "       Or set the AZURE_DEVOPS_EXT_PAT (or AZDO_PERSONAL_ACCESS_TOKEN) environment variable for direct PAT login"
      exit 1
    fi
  fi
}

_create_endpoint() {
  # Create an Azure RM type service endpoint
  local azdo_endpoint_name="${1}"
  echo -e "Creating the Azure RM service endpoint \"${azdo_endpoint_name}\" in project \"${AZURE_DEVOPS_PROJECT_NAME}\""

  # Check required environment variables
  if [ -z "${ARM_CLIENT_ID}" ]; then
    echo "ERROR: The Azure Service Principal ID was not defined"
    echo "       Set the ARM_CLIENT_ID variable to be able to create an Azure RM service endpoint"
    exit 1
  fi
  if [ -z "${AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY}" ]; then
    echo "ERROR: The Azure Service Principal Secret was not defined"
    echo "       Either ARM_CLIENT_SECRET or AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY variables must be set"
    exit 1
  fi

  # Additional checks for tenant and subscription variables required by the Azure RM integration
  az_account=$(az account show 2> /dev/null)
  tenant_id=${ARM_TENANT_ID:-$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["tenantId"])' 2> /dev/null)}
  subscription_id=${ARM_SUBSCRIPTION_ID:-$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)}
  subscription_name=${ARM_SUBSCRIPTION_NAME:-$(az account list --query "[?id=='${subscription_id}'].name" \
                                                | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0])' 2> /dev/null)}
  if [ -z "${tenant_id}" ] || [ -z "${subscription_id}" ] || [ -z "${subscription_name}" ]; then
    echo "ERROR: Could not extract the required variables needed to create an Azure RM service endpoint"
    echo "       Check 'az account show' or set the following environment variables: ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_SUBSCRIPTION_NAME"
    exit 1
  else
    echo "Will use the following parameters when creating the Azure RM service endpoint:"
    echo -e "  --azure-rm-service-principal-id \"${ARM_CLIENT_ID}\""
    echo -e "  --azure-rm-tenant-id \"${tenant_id}\""
    echo -e "  --azure-rm-subscription-id \"${subscription_id}\""
    echo -e "  --azure-rm-subscription-name \"${subscription_name}\""
  fi

  # Create the endpoint
  _response=$(az devops service-endpoint azurerm create \
                      --azure-rm-service-principal-id "${ARM_CLIENT_ID}" \
                      --azure-rm-tenant-id "${tenant_id}" \
                      --azure-rm-subscription-id "${subscription_id}" \
                      --azure-rm-subscription-name "${subscription_name}" \
                      --name "${azdo_endpoint_name}" \
                      --org "${AZURE_DEVOPS_ORG_URL}" \
                      --project "${AZURE_DEVOPS_PROJECT_NAME}")

  # Extract the endpoint id
  azdo_endpoint_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)
  [ -z "${azdo_endpoint_id}" ] && { echo "${_response}"; exit 1; }

  # Update permissions on the endpoint to all pipelines
  az devops service-endpoint update --id "${azdo_endpoint_id}" \
                                    --enable-for-all \
                                    --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                    --org "${AZURE_DEVOPS_ORG_URL}" > /dev/null || exit 1
  echo -e "Azure RM service endpoint \"${azdo_endpoint_name}\"(\"${azdo_endpoint_id}\") created successfully"
}

_delete_endpoint() {
  # Delete an Azure RM type service endpoint
  local azdo_endpoint_name="${1}"
  echo -e "Deleting the Azure RM service endpoint \"${azdo_endpoint_name}\" from project \"${AZURE_DEVOPS_PROJECT_NAME}\""

  azdo_endpoint_id=$(az devops service-endpoint list --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                                     --org "${AZURE_DEVOPS_ORG_URL}" \
                                                     --query "[?name=='${azdo_endpoint_name}'].id" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0])' 2> /dev/null )

  if ! az devops service-endpoint delete --yes \
                                         --id "${azdo_endpoint_id}" \
                                         --org "${AZURE_DEVOPS_ORG_URL}" \
                                         --project "${AZURE_DEVOPS_PROJECT_NAME}"; then
    echo -e "ERROR: Azure RM service endpoint \"${azdo_endpoint_name}\" was not deleted successfully"
    exit 1
  else
    echo -e "Azure RM service endpoint \"${azdo_endpoint_name}\" deleted successfully"
  fi
}

_update_endpoint() {
  # Update an Azure RM type service endpoint
  local azdo_endpoint_name="${1}"
  azdo_endpoint_id=$(az devops service-endpoint list --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                                     --org "${AZURE_DEVOPS_ORG_URL}" \
                                                     --query "[?name=='${azdo_endpoint_name}'].id" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0])' 2> /dev/null )

  if [ -z "${azdo_endpoint_id}" ]; then
    _create_endpoint "${azdo_endpoint_name}"
  else
    # No option to update the Service Principal using the cli so have to delete it first and recreate
    echo -e "Endpoint \"${azdo_endpoint_name}\"(\"${azdo_endpoint_id}\") already exists, deleting before updating\n"
    _delete_endpoint "${azdo_endpoint_name}"
    _create_endpoint "${azdo_endpoint_name}"
  fi
}

case "${1}" in
  create)
    _check_args "$@"
    _check_auth
    _install_extension
    _update_endpoint "${2}"
    ;;
  delete)
    _check_args "$@"
    _check_auth
    _install_extension
    _delete_endpoint "${2}"
    ;;
  *)
    _usage
    ;;
esac
