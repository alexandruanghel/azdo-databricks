#!/usr/bin/env bash
#
# Retrieves a Databricks Object ID using the Workspace API (https://docs.databricks.com/dev-tools/api/latest/workspace.html).
# It uses simple positional arguments.
# Returns the Object ID as a variable called workspaceObjectId in the Azure Pipelines format.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_object_path=${3}

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> <object_path>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_object_path}" ] && _usage

# Call the Databricks workspace API
echo -e "Getting the Object ID of \"${_object_path}\""
_response=$(curl -sS --request GET \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Content-Type: application/json" \
                     "${_workspace_url}/api/2.0/workspace/get-status?path=${_object_path}")

# Extract the Object ID from response
object_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["object_id"])' 2> /dev/null)
[ -z "${object_id}" ] && { echo "${_response}"; exit 1; }
echo -e "Got the Object ID: ${object_id}"

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${object_id}" ] && echo "##vso[task.setvariable variable=workspaceObjectId;issecret=false]${object_id}"
fi
