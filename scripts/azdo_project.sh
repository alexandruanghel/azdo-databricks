#!/usr/bin/env bash
#
# Manages an Azure DevOps project (using https://docs.microsoft.com/en-us/cli/azure/devops/project).
# It uses both positional arguments and environment variables.
#

# Debug
#set -x

# Local variables
_python="$(command -v python || command -v python3)"

# Environment variables
export AZURE_DEVOPS_ORG_URL=${AZURE_DEVOPS_ORG_URL:-${AZDO_ORG_SERVICE_URL}}
export AZURE_DEVOPS_EXT_PAT=${AZURE_DEVOPS_EXT_PAT:-${AZDO_PERSONAL_ACCESS_TOKEN}}


_usage() {
  echo -e "Usage: ${0} {create|delete} <project_name>"
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
}

_check_auth() {
  # Check the existing Azure Authentication
  if [ -z "${AZURE_DEVOPS_EXT_PAT}" ]; then
    az_signed_in_user=$(az ad signed-in-user show --query userPrincipalName --output tsv)
    if [ -z "${az_signed_in_user}" ]; then
      echo "ERROR: User Principal not logged in, run 'az login' first (az login with a Service Principal is not supported)"
      echo "       Or set the AZURE_DEVOPS_EXT_PAT (or AZDO_PERSONAL_ACCESS_TOKEN) environment variable for direct PAT login"
      exit 1
    fi
  fi
}

_create_project() {
  # Create an Azure DevOps project
  local azdo_project_name="${1}"
  echo -e "Creating the Azure DevOps project \"${azdo_project_name}\" in organization \"${AZURE_DEVOPS_ORG_URL}\""
  azdo_project_id=$(az devops project show --project "${azdo_project_name}" --org "${AZURE_DEVOPS_ORG_URL}" --query id --output tsv)
  if [ -n "${azdo_project_id}" ]; then
    echo -e "Azure DevOps project \"${azdo_project_name}\" already exists with id \"${azdo_project_id}\""
  else
    azdo_project_id=$(az devops project create --name "${azdo_project_name}" --org "${AZURE_DEVOPS_ORG_URL}" \
                        | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null )
    if [ -n "${azdo_project_id}" ]; then
      echo -e "Azure DevOps project \"${azdo_project_name}\" created successfully"
    else
      echo -e "ERROR: Azure DevOps project \"${azdo_project_name}\" was not created successfully"
      exit 1
    fi
  fi
}

_delete_project() {
  # Delete an Azure DevOps project
  local azdo_project_name="${1}"
  echo -e "Deleting the Azure DevOps project \"${azdo_project_name}\" from organization \"${AZURE_DEVOPS_ORG_URL}\""

  azdo_project_id=$(az devops project show --project "${azdo_project_name}" --org "${AZURE_DEVOPS_ORG_URL}" --query id --output tsv)
  if ! az devops project delete --yes --id "${azdo_project_id}" --org "${AZURE_DEVOPS_ORG_URL}"; then
    echo -e "ERROR: Azure DevOps project \"${azdo_project_name}\" was not deleted successfully"
    exit 1
  else
    echo -e "Azure DevOps project \"${azdo_project_name}\" deleted successfully"
  fi
}

case "${1}" in
  create)
    _check_args "$@"
    _check_auth
    _install_extension
    _create_project "${2}"
    ;;
  delete)
    _check_args "$@"
    _check_auth
    _install_extension
    _delete_project "${2}"
    ;;
  *)
    _usage
    ;;
esac
