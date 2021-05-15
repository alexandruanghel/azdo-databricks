#!/usr/bin/env bash
#
# Manages an Azure DevOps Pipeline variable (using https://docs.microsoft.com/en-us/cli/azure/pipelines/variable).
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

# Azure GitHub service endpoint parameters
export AZURE_DEVOPS_GITHUB_ENDPOINT_NAME=${AZURE_DEVOPS_GITHUB_ENDPOINT_NAME:-"MyGithubEndpoint"}
export AZURE_DEVOPS_GITHUB_REPO_URL=${AZURE_DEVOPS_GITHUB_REPO_URL:-"https://github.com/alexandruanghel/azdo-databricks"}
export AZURE_DEVOPS_GITHUB_BRANCH=${AZURE_DEVOPS_GITHUB_BRANCH:-"master"}

# Azure pipeline parameters
export AZURE_DEVOPS_PIPELINE_PATH=${AZURE_DEVOPS_PIPELINE_PATH:-"pipelines/azure-pipelines-full.yml"}


_usage() {
  echo -e "Usage: ${0} {create|update|delete} <pipeline_name> <variable_name> <variable_value>"
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
  if [ -z "${AZURE_DEVOPS_EXT_PAT}" ]; then
    az_signed_in_user=$(az ad signed-in-user show 2> /dev/null | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["userPrincipalName"])' 2> /dev/null)
    if [ -z "${az_signed_in_user}" ]; then
      echo "ERROR: User Principal not logged in, run 'az login' first (az login with a Service Principal is not supported)"
      echo "       Or set the AZURE_DEVOPS_EXT_PAT (or AZDO_PERSONAL_ACCESS_TOKEN) environment variable for direct PAT login"
      exit 1
    fi
  fi
}

_create_variable() {
  # Create a Pipeline variable
  local azdo_pipeline_name="${1}"
  local azdo_variable_name="${2}"
  local azdo_variable_value="${3}"
  [ -z "${azdo_pipeline_name}" ] || [ -z "${azdo_variable_name}" ] || [ -z "${azdo_variable_value}" ] && _usage

  echo -e "Creating the variable \"${azdo_variable_name}\" in pipeline \"${azdo_pipeline_name}\""
  # Check of the variable is already set
  _var_value=$(az pipelines variable list --pipeline-name "${azdo_pipeline_name}" \
                                          --org "${AZURE_DEVOPS_ORG_URL}" \
                                          --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                          --query "${azdo_variable_name}.value")

  # Set the operation type (create or update) depending on the variable state
  if [ -z "${_var_value}" ]; then
    _var_op="create"
  else
    _var_op="update"
  fi

  # Create or updates the variable
  if ! az pipelines variable ${_var_op} --name "${azdo_variable_name}" \
                                        --allow-override true \
                                        --pipeline-name "${azdo_pipeline_name}" \
                                        --value "${azdo_variable_value}" \
                                        --org "${AZURE_DEVOPS_ORG_URL}" \
                                        --project "${AZURE_DEVOPS_PROJECT_NAME}" > /dev/null; then
    echo -e "ERROR: Pipeline variable \"${azdo_variable_name}\" was not created successfully in pipeline \"${azdo_pipeline_name}\""
    exit 1
  else
    echo -e "Pipeline variable \"${azdo_variable_name}\" created successfully in pipeline \"${azdo_pipeline_name}\""
  fi
}

_delete_variable() {
  # Delete a Pipeline variable
  local azdo_pipeline_name="${1}"
  local azdo_variable_name="${2}"
  [ -z "${azdo_pipeline_name}" ] || [ -z "${azdo_variable_name}" ] && _usage

  echo -e "Deleting the variable \"${azdo_variable_name}\" from pipeline \"${azdo_pipeline_name}\""
  azdo_pipeline_id=$(az pipelines show --name "${azdo_pipeline_name}" \
                                       --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                       --org "${AZURE_DEVOPS_ORG_URL}" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)
  if ! az pipelines variable delete --yes \
                           --name "${azdo_variable_name}" \
                           --pipeline-id "${azdo_pipeline_id}" \
                           --pipeline-name "${azdo_pipeline_name}" \
                           --org "${AZURE_DEVOPS_ORG_URL}" \
                           --project "${AZURE_DEVOPS_PROJECT_NAME}"; then
    echo -e "ERROR: Pipeline variable \"${azdo_variable_name}\" was not deleted successfully"
    exit 1
  else
    echo -e "Pipeline variable \"${azdo_variable_name}\" deleted successfully"
  fi
}

case "${1}" in
  create|update)
    _check_args "$@"
    _check_auth
    _install_extension
    _create_variable "${2}" "${3}" "${4}"
    ;;
  delete)
    _check_args "$@"
    _check_auth
    _install_extension
    _delete_variable "${2}" "${3}"
    ;;
  *)
    _usage
    ;;
esac
