#!/usr/bin/env bash
#
# Manages an Azure DevOps Pipeline (using https://docs.microsoft.com/en-us/cli/azure/pipelines).
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


_usage() {
  echo -e "Usage: ${0} {create|delete} <pipeline_name> <pipeline_path>"
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

_create_pipeline() {
  # Create an Azure Pipeline for the repository hosted on Github
  local azdo_pipeline_name="${1}"
  local azdo_pipeline_path="${2}"

  echo -e "Creating the Azure Pipeline \"${azdo_pipeline_name}\" in project \"${AZURE_DEVOPS_PROJECT_NAME}\""

  # Additional checks for variables required to create a pipeline
  if [ -z "${AZURE_DEVOPS_GITHUB_ENDPOINT_NAME}" ]; then
    echo "ERROR: The GitHub Endpoint name was not defined"
    echo "       The AZURE_DEVOPS_GITHUB_ENDPOINT_NAME variable must be set"
    exit 1
  fi

  azdo_endpoint_id=${AZURE_DEVOPS_GITHUB_ENDPOINT_ID:-$(az devops service-endpoint list --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                                                                        --org "${AZURE_DEVOPS_ORG_URL}" \
                                                                                        --query "[?name=='${AZURE_DEVOPS_GITHUB_ENDPOINT_NAME}'].id" \
                                                         | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0])' 2> /dev/null )}
  if [ -z "${azdo_endpoint_id}" ]; then
    echo "ERROR: Could not extract the ID of the Service connection \"${AZURE_DEVOPS_GITHUB_ENDPOINT_NAME}\" from project \"${AZURE_DEVOPS_PROJECT_NAME}\""
    echo "       Set the AZURE_DEVOPS_PROJECT_NAME and AZURE_DEVOPS_GITHUB_ENDPOINT_NAME environment variables to a correct value"
    echo "       Or check 'az devops service-endpoint list --project \"${AZURE_DEVOPS_PROJECT_NAME}\" --org \"${AZURE_DEVOPS_ORG_URL}\"' and set the AZURE_DEVOPS_GITHUB_ENDPOINT_ID environment variable"
    exit 1
  else
    echo "Will use the following parameters when creating the Azure Pipeline:"
    echo -e "  --service-connection \"${azdo_endpoint_id}\""
    echo -e "  --repository \"${AZURE_DEVOPS_GITHUB_REPO_URL}\""
    echo -e "  --branch \"${AZURE_DEVOPS_GITHUB_BRANCH}\""
    echo -e "  --yaml-path \"${azdo_pipeline_path}\""
  fi

  azdo_pipeline_id=$(az pipelines show --name "${azdo_pipeline_name}" \
                                       --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                       --org "${AZURE_DEVOPS_ORG_URL}" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)

  if [ -n "${azdo_pipeline_id}" ]; then
    echo -e "Azure Pipeline \"${azdo_pipeline_name}\" already exists with id \"${azdo_pipeline_id}\""
  else
    azdo_pipeline_id=$(az pipelines create --name "${azdo_pipeline_name}" \
                                           --skip-first-run \
                                           --service-connection "${azdo_endpoint_id}" \
                                           --repository "${AZURE_DEVOPS_GITHUB_REPO_URL}" \
                                           --repository-type github \
                                           --branch "${AZURE_DEVOPS_GITHUB_BRANCH}" \
                                           --yaml-path "${azdo_pipeline_path}" \
                                           --org "${AZURE_DEVOPS_ORG_URL}" \
                                           --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                        | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)
    if [ -n "${azdo_pipeline_id}" ]; then
      echo -e "Azure Pipeline \"${azdo_pipeline_name}\"(\"${azdo_pipeline_id}\") created successfully in project \"${AZURE_DEVOPS_PROJECT_NAME}\""
    else
      echo -e "ERROR: Azure Pipeline \"${azdo_pipeline_name}\" was not created successfully in project \"${AZURE_DEVOPS_PROJECT_NAME}\""
      exit 1
    fi
  fi
}

_delete_pipeline() {
  # Delete an Azure Pipeline for the repository hosted on Github
  local azdo_pipeline_name="${1}"
  echo -e "Deleting the Azure Pipeline \"${azdo_pipeline_name}\" from project \"${AZURE_DEVOPS_PROJECT_NAME}\""

  azdo_pipeline_id=$(az pipelines show --name "${azdo_pipeline_name}" \
                                       --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                       --org "${AZURE_DEVOPS_ORG_URL}" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)
  if ! az pipelines delete --yes \
                           --id "${azdo_pipeline_id}" \
                           --org "${AZURE_DEVOPS_ORG_URL}" \
                           --project "${AZURE_DEVOPS_PROJECT_NAME}"; then
    echo -e "ERROR: Azure Pipeline \"${azdo_pipeline_name}\" was not deleted successfully"
    exit 1
  else
    echo -e "Azure Pipeline \"${azdo_pipeline_name}\" deleted successfully"
  fi
}

case "${1}" in
  create)
    _check_args "$@"
    _check_auth
    _install_extension
    _create_pipeline "${2}" "${3}"
    ;;
  delete)
    _check_args "$@"
    _check_auth
    _install_extension
    _delete_pipeline "${2}"
    ;;
  *)
    _usage
    ;;
esac
