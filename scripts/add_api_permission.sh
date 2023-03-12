#!/usr/bin/env bash
#
# Adds an API Permission to a Service Principal (https://docs.microsoft.com/en-us/graph/permissions-reference).
# Works with either Azure Active Directory Graph API or Microsoft Graph API.
# It uses simple positional arguments.
#

# Required parameters
_api_permission=${1}
_sp_client_id=${2}

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_python="$(command -v python || command -v python3)"
_msGraphResourceId="00000003-0000-0000-c000-000000000000"          # Microsoft Graph API ID

_usage() {
  echo -e "Usage: ${0} <api_permission> <sp_client_id>"
  exit 1
}

# Parameters check
[ -z "${_api_permission}" ] && _usage
[ -z "${_sp_client_id}" ] && _usage

# Get the API Permission ID
echo -e "Getting the ID for \"${_api_permission}\""
api_permission_id=$(az ad sp show --id ${_msGraphResourceId} --query "appRoles[?value=='${_api_permission}']" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')
[ -z "${api_permission_id}" ] && exit 1
echo -e "Got the API Permission ID: \"${api_permission_id}\""

# Use the az cli command to set the API Permission
echo -e "Setting the API Permission on the Service Principal \"${_sp_client_id}\""
timer=0
while [ ${timer} -lt 100 ]; do
  az ad app permission add --id "${_sp_client_id}" \
                           --api "${_msGraphResourceId}" \
                           --api-permissions "${api_permission_id}=Role" && break
  echo -e "Principal \"${_sp_client_id}\" might not be accessible yet, sleeping for 10 seconds"
  sleep 10 && timer=$((timer+10)) && (exit 1)
done || { echo "ERROR: Timed out waiting"; exit 1; }


#  az ad app permission grant --id "${_sp_client_id}" \
#                           --api "${_adGraphResourceId}" \
#                           --scope "${api_permission_id}" || exit 1

# Grant admin-consent using the CLI command
echo -e "Granting admin-consent to the Service Principal \"${_sp_client_id}\""
sleep 10
az ad app permission admin-consent --id "${_sp_client_id}" || exit 1
