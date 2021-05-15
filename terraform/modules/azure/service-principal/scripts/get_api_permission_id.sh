#!/usr/bin/env bash

# Local variables
_python="$(command -v python || command -v python3)"
_msGraphResourceId="00000003-0000-0000-c000-000000000000"          # Microsoft Graph API ID
_adGraphResourceId="00000002-0000-0000-c000-000000000000"          # Azure Active Directory Graph API ID

# Required parameters
stdin="$(cat -)"
_graph_type=${1:-$(echo "$stdin" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["graph_type"])' )}
_api_permission=${2:-$(echo "$stdin" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["api_permission"])' )}


_usage() {
  echo -e "Usage: "echo '"{\"graph_type\": \"[ad|microsoft]\", \"api_permission\": \"<api_permission>\"}"'" | ${0}"
  exit 1
}

# Parameters check
[ -z "${_graph_type}" ] && _usage
[ -z "${_api_permission}" ] && _usage

if [ "${_graph_type}" == "ad" ]; then
  graphResourceId="${_adGraphResourceId}"
elif [ "${_graph_type}" == "microsoft" ]; then
  graphResourceId="${_msGraphResourceId}"
else
  _usage
fi

# Login to the az cli
if [ -n "${ARM_CLIENT_ID}" ] && [ -n "${ARM_CLIENT_SECRET}" ] && [ -n "${ARM_TENANT_ID}" ]; then
  export AZURE_CONFIG_DIR=~/.azure-api_permission
  az login --service-principal --username "${ARM_CLIENT_ID}" --password "${ARM_CLIENT_SECRET}" --tenant "${ARM_TENANT_ID}" --allow-no-subscriptions > /dev/null || exit 1
  az account set --subscription "${ARM_SUBSCRIPTION_ID}" || exit 1
fi

# Gets the API Permission ID
api_permission_id=$(az ad sp show --id ${graphResourceId} --query "appRoles[?value=='${_api_permission}']" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')
[ -z "${api_permission_id}" ] && exit 1

# Passes the result back to Terraform
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${api_permission_id}" ] && echo "{\"api_permission_id\": \"${api_permission_id}\"}" || exit 1
fi

# Logout
if [ -n "${ARM_CLIENT_ID}" ] && [ -n "${ARM_CLIENT_SECRET}" ] && [ -n "${ARM_TENANT_ID}" ]; then
  az account clear
fi
