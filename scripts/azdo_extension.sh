#!/usr/bin/env bash
#
# Manages an Azure DevOps extension (using https://docs.microsoft.com/en-us/cli/azure/devops/extension).
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
  echo -e "Usage: ${0} {install|uninstall} <extension-id> <publisher-id>"
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
    az_signed_in_user=$(az ad signed-in-user show 2> /dev/null | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["userPrincipalName"])' 2> /dev/null)
    if [ -z "${az_signed_in_user}" ]; then
      echo "ERROR: User Principal not logged in, run 'az login' first (az login with a Service Principal is not supported)"
      echo "       Or set the AZURE_DEVOPS_EXT_PAT (or AZDO_PERSONAL_ACCESS_TOKEN) environment variable for direct PAT login"
      exit 1
    fi
  fi
}

_install() {
  # Install the Azure DevOps extension
  local _extension_id="${1}"
  local _publisher_id="${2}"
  echo -e "Installing the extension \"${_extension_id}\" of publisher \"${_publisher_id}\""

  _response=$(az devops extension install \
                     --extension-id "${_extension_id}" \
                     --publisher-id "${_publisher_id}" \
                     --organization "${AZURE_DEVOPS_ORG_URL}" 2>&1 )
  if [ -n "$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["extensionId"])' 2> /dev/null)" ] || \
     echo "${_response}" | grep "TF1590010" > /dev/null; then
    echo -e "Extension installed successfully or already installed"
  else
    echo -e "${_response}"
    exit 1
  fi
}

_uninstall() {
  # Uninstall the Azure DevOps extension
  local _extension_id="${1}"
  local _publisher_id="${2}"
  echo -e "Uninstalling the extension \"${_extension_id}\" of publisher \"${_publisher_id}\""

  _response=$(az devops extension uninstall --yes \
                     --extension-id "${_extension_id}" \
                     --publisher-id "${_publisher_id}" \
                     --organization "${AZURE_DEVOPS_ORG_URL}" 2>&1 )
  if [ -z "${_response}" ]; then
    echo -e "Extension uninstalled successfully"
  else
    echo -e "${_response}"
    exit 1
  fi
}

case "${1}" in
  install)
    _check_args "$@"
    _check_auth
    _install_extension
    _install "${2}" "${3}"
    ;;
  uninstall)
    _check_args "$@"
    _check_auth
    _install_extension
    _uninstall "${2}" "${3}"
    ;;
  *)
    _usage
    ;;
esac
