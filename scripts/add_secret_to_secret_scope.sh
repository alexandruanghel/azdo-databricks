#!/usr/bin/env bash
#
# Adds a secret to a Databricks Secret Scope using the Secrets API (https://docs.databricks.com/dev-tools/api/latest/secrets.html).
# It uses simple positional arguments.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_secret_scope_name=${3}
_secret_name=${4}
_secret_value=${5}

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> <secret_scope_name> <secret_name> <secret_value>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_secret_scope_name}" ] && _usage
[ -z "${_secret_name}" ] && _usage
[ -z "${_secret_value}" ] && _usage

# Set the payload
payload='
{
  "scope": "'${_secret_scope_name}'",
  "key": "'${_secret_name}'",
  "string_value": "'${_secret_value}'"
}
'

# Call the Databricks Secrets API
echo -e "Storing the secret \"${_secret_name}\" in the Secret Scope \"${_secret_scope_name}\""
_response=$(curl -sS --request POST \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Content-Type: application/json" \
                     "${_workspace_url}/api/2.0/secrets/put" \
                     -d "${payload}")

# Return ok if there is no error code
if [ "${_response}" == "{}" ]; then
  echo -e "Secret \"${_secret_name}\" stored"
else
  echo "${_response}"
  exit 1
fi
