#!/usr/bin/env bash
#
# Adds an API Permission to a Service Principal (https://docs.microsoft.com/en-us/graph/permissions-reference).
# Works with either Azure Active Directory Graph API or Microsoft Graph API.
# It uses simple positional arguments.
#

# Required parameters
_graph_type=${1}
_api_permission=${2}
_sp_client_id=${3}

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_python="$(command -v python || command -v python3)"
_msGraphResourceId="00000003-0000-0000-c000-000000000000"          # Microsoft Graph API ID
_adGraphResourceId="00000002-0000-0000-c000-000000000000"          # Azure Active Directory Graph API ID

_usage() {
  echo -e "Usage: ${0} [ad|microsoft] <api_permission> <sp_client_id>"
  exit 1
}

# Parameters check
[ -z "${_graph_type}" ] && _usage
[ -z "${_api_permission}" ] && _usage
[ -z "${_sp_client_id}" ] && _usage

echo -e "Graph type set to ${_graph_type}"
if [ "${_graph_type}" == "ad" ]; then
  graphResourceId="${_adGraphResourceId}"
elif [ "${_graph_type}" == "microsoft" ]; then
  graphResourceId="${_msGraphResourceId}"
else
  _usage
fi

# Get the API Permission ID
echo -e "Getting the ID for \"${_api_permission}\""
api_permission_id=$(az ad sp show --id ${graphResourceId} --query "appRoles[?value=='${_api_permission}']" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')
[ -z "${api_permission_id}" ] && exit 1
echo -e "Got the API Permission ID: \"${api_permission_id}\""

# Set the API Permission depending on the Graph API type
if [ "${_graph_type}" == "ad" ]; then
  # Use the az cli command to set the API Permission
  echo -e "Setting the API Permission on the Service Principal \"${_sp_client_id}\""
  timer=0
  while [ ${timer} -lt 100 ]; do
    az ad app permission add --id "${_sp_client_id}" \
                             --api "${_adGraphResourceId}" \
                             --api-permissions "${api_permission_id}=Role" && break
    echo -e "Principal \"${_sp_client_id}\" might not be accessible yet, sleeping for 10 seconds"
    sleep 10 && timer=$((timer+10)) && (exit 1)
  done || { echo "ERROR: Timed out waiting"; exit 1; }

  # Grant admin-consent using the CLI command
  echo -e "Granting admin-consent to the Service Principal \"${_sp_client_id}\""
  az ad app permission admin-consent --id "${_sp_client_id}" || exit 1
else
  # Get the Object ID of MS Graph Service Principal
  source "${_script_dir}/get_object_details.sh" "${_msGraphResourceId}"
  graph_object_id=${object_id}

  # Get the Object ID of Service Principal
  source "${_script_dir}/get_object_details.sh" "${_sp_client_id}"
  sp_object_id=${object_id}

  # Set the payload
  payload='
  {
    "principalId":"'${sp_object_id}'",
    "resourceId":"'${graph_object_id}'",
    "appRoleId":"'${api_permission_id}'"
  }
  '

  # Call az rest (Microsoft Graph is not yet supported by the Azure CLI)
  echo -e "Calling az rest to set the API Permission"
  timer=0
  while [ ${timer} -lt 100 ]; do
    _response=$(az rest --method POST \
                        --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${graph_object_id}/appRoleAssignedTo" \
                        --body "${payload}" 2>&1 )
    if [ -n "$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])' 2> /dev/null)" ] || \
       echo "${_response}" | grep "Permission being assigned already exists on the object" > /dev/null; then
      echo "API Permission set successfully"
      break
    fi
    echo -e "Principal \"${_sp_client_id}\" might not be accessible yet, sleeping for 10 seconds"
    sleep 10 && timer=$((timer+10)) && (exit 1)
  done || { echo "ERROR: Timed out waiting"; exit 1; }
fi
