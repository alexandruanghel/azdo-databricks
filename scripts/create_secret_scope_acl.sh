#!/usr/bin/env bash
#
# Creates a Databricks Secret Scope ACL using the Secrets API (https://docs.databricks.com/dev-tools/api/latest/secrets.html).
# It uses simple positional arguments.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_secret_scope_name=${3}
_principal=${4}
_permission=${5}

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> <secret_scope_name> <principal> <permission>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_secret_scope_name}" ] && _usage
[ -z "${_principal}" ] && _usage
[ -z "${_permission}" ] && _usage

# Set the payload
payload='
{
  "scope": "'${_secret_scope_name}'",
  "principal": "'${_principal}'",
  "permission": "'${_permission}'"
}
'

# Call the Databricks Secrets API
echo -e "Adding the \"${_permission}\" permission to principal \"${_principal}\" to \"${_secret_scope_name}\" secret scope"
_response=$(curl -sS --request POST \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Content-Type: application/json" \
                     "${_workspace_url}/api/2.0/secrets/acls/put" \
                     -d "${payload}")

# Get the error code
_error_code=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["error_code"])' 2> /dev/null)

# Return ok if ACL was created or already exists
if [ "${_response}" == "{}" ] || [ "${_error_code}" == "RESOURCE_ALREADY_EXISTS" ]; then
  echo -e "ACL \"${_permission}\" added or already exists"
else
  echo "${_response}"
  exit 1
fi
