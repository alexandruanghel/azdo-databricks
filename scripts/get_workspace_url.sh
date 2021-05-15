#!/usr/bin/env bash
#
# Retrieves a Databricks workspace URL using the Azure CLI ('az resource show').
# It uses simple positional arguments.
# Returns the workspace URL as a variable called databricksWorkspaceUrl in the Azure Pipelines format.
# Returns the workspace ID as a variable called databricksWorkspaceId in the Azure Pipelines format.
# Returns the workspace hostname as a variable called databricksWorkspaceHostname in the Azure Pipelines format.
#

# Required parameters
_resource_group_name=${1}
_workspace_name=${2}

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <resource_group_name> <workspace_name>"
  exit 1
}

# Parameters check
[ -z "${_resource_group_name}" ] && _usage
[ -z "${_workspace_name}" ] && _usage

# Use the az cli command
echo -e "Getting the URL of Workspace ${_workspace_name} from Resource Group ${_resource_group_name}"
_response=$(az resource show --name "${_workspace_name}" \
                             --resource-type "Microsoft.Databricks/workspaces" \
                             --resource-group "${_resource_group_name}" \
                             --output json)
[ -z "${_response}" ] && exit 1

# Get the Databricks workspace URL from response
workspace_hostname=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["properties"]["workspaceUrl"])')
[ -z "${workspace_hostname}" ] && { echo "${_response}"; exit 1; }
workspace_url="https://${workspace_hostname}"
echo -e "Got the URL: ${workspace_url}"

# Get the Databricks workspace Resource ID from response
workspace_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])')
[ -z "${workspace_id}" ] && { echo "${_response}"; exit 1; }

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${workspace_id}" ] && echo "##vso[task.setvariable variable=databricksWorkspaceId;issecret=false]${workspace_id}"
  [ -n "${workspace_hostname}" ] && echo "##vso[task.setvariable variable=databricksWorkspaceHostname;issecret=false]${workspace_hostname}"
  [ -n "${workspace_url}" ] && echo "##vso[task.setvariable variable=databricksWorkspaceUrl;issecret=false]${workspace_url}"
fi
