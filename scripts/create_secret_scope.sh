#!/usr/bin/env bash
#
# Creates a Databricks Secret Scope using the Secrets API (https://docs.databricks.com/dev-tools/api/latest/secrets.html).
# It uses simple positional arguments.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_secret_scope_name=${3}

# Local variables
_python="$(command -v python || command -v python3)"

# Optional parameters
initial_manage_principal=${4}

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> <secret_scope_name>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_secret_scope_name}" ] && _usage

# Set the payload
payload='
{
  "scope": "'${_secret_scope_name}'"
  '$([ -n "${initial_manage_principal}" ] && echo ',"initial_manage_principal": "test"')'
}
'

# Call the Databricks Secrets API
echo -e "Creating the Secret Scope \"${_secret_scope_name}\""
_response=$(curl -sS --request POST \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Content-Type: application/json" \
                     "${_workspace_url}/api/2.0/secrets/scopes/create" \
                     -d "${payload}")
_error_code=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["error_code"])' 2> /dev/null)

if [ "${_response}" == "{}" ] || [ "${_error_code}" == "RESOURCE_ALREADY_EXISTS" ]; then
  echo -e "Secret Scope \"${_secret_scope_name}\" created or already exists"
else
  echo "${_response}"
  exit 1
fi
