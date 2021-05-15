#!/usr/bin/env bash
#
# Manages an Azure DevOps GitHub service endpoint (using https://docs.microsoft.com/en-us/cli/azure/devops/service-endpoint/github).
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

# Azure GitHub service endpoint variables
export AZURE_DEVOPS_GITHUB_REPO_URL=${AZURE_DEVOPS_GITHUB_REPO_URL:-"https://github.com/alexandruanghel/azdo-databricks"}
export AZURE_DEVOPS_EXT_GITHUB_PAT=${AZURE_DEVOPS_EXT_GITHUB_PAT:-${AZDO_GITHUB_SERVICE_CONNECTION_PAT}}


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
  if [ -z "${AZURE_DEVOPS_EXT_PAT}" ]; then
    az_signed_in_user=$(az ad signed-in-user show 2> /dev/null | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["userPrincipalName"])' 2> /dev/null)
    if [ -z "${az_signed_in_user}" ]; then
      echo "ERROR: User Principal not logged in, run 'az login' first (az login with a Service Principal is not supported)"
      echo "       Or set the AZURE_DEVOPS_EXT_PAT (or AZDO_PERSONAL_ACCESS_TOKEN) environment variable for direct PAT login"
      exit 1
    fi
  fi
}

_create_endpoint() {
  # Create a GitHub type service endpoint
  local azdo_endpoint_name="${1}"
  echo -e "Creating the GitHub type service endpoint \"${azdo_endpoint_name}\" in project \"${AZURE_DEVOPS_PROJECT_NAME}\""

  # Check required environment variables
  if [ -z "${AZURE_DEVOPS_EXT_GITHUB_PAT}" ]; then
    echo "ERROR: The GitHub PAT token was not defined"
    echo "       Either AZURE_DEVOPS_EXT_GITHUB_PAT or AZDO_GITHUB_SERVICE_CONNECTION_PAT variables must be set"
    exit 1
  fi

  # Check if endpoint already exists
  azdo_endpoint_id=$(az devops service-endpoint list --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                                     --org "${AZURE_DEVOPS_ORG_URL}" \
                                                     --query "[?name=='${azdo_endpoint_name}'].id" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0])' 2> /dev/null )

  if [ -z "${azdo_endpoint_id}" ]; then
    # Create the endpoint
    _response=$(az devops service-endpoint github create \
                          --github-url "${AZURE_DEVOPS_GITHUB_REPO_URL}" \
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
    echo -e "GitHub service endpoint \"${azdo_endpoint_name}\"(\"${azdo_endpoint_id}\") created successfully"
  else
    echo -e "Endpoint \"${azdo_endpoint_name}\"(\"${azdo_endpoint_id}\") already exists"
  fi
}

_delete_endpoint() {
  # Delete a GitHub type service endpoint
  local azdo_endpoint_name="${1}"
  echo -e "Deleting the GitHub type service endpoint \"${azdo_endpoint_name}\" from project \"${AZURE_DEVOPS_PROJECT_NAME}\""

  azdo_endpoint_id=$(az devops service-endpoint list --project "${AZURE_DEVOPS_PROJECT_NAME}" \
                                                     --org "${AZURE_DEVOPS_ORG_URL}" \
                                                     --query "[?name=='${azdo_endpoint_name}'].id" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0])' 2> /dev/null )

  if ! az devops service-endpoint delete --yes \
                                         --id "${azdo_endpoint_id}" \
                                         --org "${AZURE_DEVOPS_ORG_URL}" \
                                         --project "${AZURE_DEVOPS_PROJECT_NAME}"; then
    echo -e "ERROR: GitHub service endpoint \"${azdo_endpoint_name}\" was not deleted successfully"
    exit 1
  else
    echo -e "GitHub service endpoint \"${azdo_endpoint_name}\" deleted successfully"
  fi
}

case "${1}" in
  create)
    _check_args "$@"
    _check_auth
    _install_extension
    _create_endpoint "${2}"
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
