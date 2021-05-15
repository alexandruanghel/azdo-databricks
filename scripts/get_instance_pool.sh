#!/usr/bin/env bash
#
# Retrieves a Databricks Instance Pool ID using the Instance Pools API (https://docs.databricks.com/dev-tools/api/latest/instance-pools.html).
# It uses simple positional arguments.
# Returns the pool id as a variable called databricksPoolId in the Azure Pipelines format.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_instance_pool_name=${3}

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> <instance_pool_name>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_instance_pool_name}" ] && _usage


# Call the Databricks Instance Pools API
echo -e "Getting the Instance Pool ID of Pool \"${_instance_pool_name}\""
_response=$(curl -sS --request GET \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Content-Type: application/json" \
                     "${_workspace_url}/api/2.0/instance-pools/list")

# Extract the Pool ID from response
if [ -z "${_response}" ] || [ "${_response}" == "{}" ]; then
  echo -e "Instance Pool \"${_instance_pool_name}\" not found"
  exit 1
else
  instance_pool_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print([ p["instance_pool_id"] for p in json.load(sys.stdin)["instance_pools"] if p["instance_pool_name"] == "'"${_instance_pool_name}"'" ][0])')
  [ -z "${instance_pool_id}" ] && { echo "${_response}"; exit 1; }
  echo -e "Got the Instance Pool ID: ${instance_pool_id}"
fi

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${instance_pool_id}" ] && echo "##vso[task.setvariable variable=databricksPoolId;issecret=false]${instance_pool_id}"
fi
