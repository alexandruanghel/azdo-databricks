#!/usr/bin/env bash
#
# Adds a Databricks workspace permission using the Permissions API (https://docs.databricks.com/dev-tools/api/latest/permissions.html).
# It uses simple positional arguments.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_resource_type=${3}
_resource_id=${4}
_principal_type=${5}
_principal_id=${6}
_permission=${7}

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> <resource_type> <resource_id> [user, group, service_principal] <principal_id> <permission>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_resource_type}" ] && _usage
[ -z "${_resource_id}" ] && _usage
[ -z "${_principal_type}" ] && _usage
[ -z "${_principal_id}" ] && _usage
[ -z "${_permission}" ] && _usage

# Set the payload
payload='
{
  "access_control_list": [
    {
      "'${_principal_type}'_name": "'${_principal_id}'",
      "permission_level": "'${_permission}'"
    }
  ]
}
'

# Call the Databricks Permissions API
echo -e "Setting the \"${_permission}\" permission to principal \"${_principal_id}\" on \"${_resource_type}\" \"${_resource_id}\""
_response=$(curl -sS --request PATCH \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Content-Type: application/json" \
                     "${_workspace_url}/api/2.0/preview/permissions/${_resource_type}/${_resource_id}" \
                     -d "${payload}")

# Get the error code
_error_code=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["error_code"])' 2> /dev/null)

# Return ok if there is no error code
if [ "${_response}" == "{}" ] || [ -z "${_error_code}" ]; then
  echo -e "Permission level \"${_permission}\" set"
else
  echo "${_response}"
  exit 1
fi
