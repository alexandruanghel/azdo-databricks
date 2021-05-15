#!/usr/bin/env bash
#
# Creates a Databricks Cluster Policy using the Cluster Policies API (https://docs.databricks.com/dev-tools/api/latest/policies.html).
# It uses simple positional arguments.
# Returns the Policy ID as a variable called databricksPolicyId in the Azure Pipelines format.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_policy_name=${3}
_policy_file=${4}

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <workspace_url> <policy_name> <policy_file>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_policy_name}" ] && _usage
[ -z "${_policy_file}" ] && _usage

policy_definition=$(cat "${_policy_file}")
[ -z "${policy_definition}" ] && exit 1

# Call the policies API to get all existing policies
echo -e "Getting all Cluster Policies"
_response=$(curl -sS --request GET \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Content-Type: application/json" \
                     "${_workspace_url}/api/2.0/policies/clusters/list")

_total_count=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["total_count"])' 2> /dev/null)
if [ -z "${_total_count}" ]; then
  echo "${_response}"
  exit 1
else
  policy_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print([ p["policy_id"] for p in json.load(sys.stdin)["policies"] if p["name"] == "'"${_policy_name}"'" ][0])' 2> /dev/null)
fi

# Set the base payload
base_payload='
  "name": "'${_policy_name}'",
  "definition": "'${policy_definition//\"/$'\\"'}'"
'

# Create the Policy if it doesn't exist, otherwise update it
if [ "${_total_count}" == 0 ] || [ -z "${policy_id}" ]; then
  echo -e "Creating the Cluster Policy \"${_policy_name}\""
  payload='{'${base_payload}'}'
  _response=$(curl -sS --request POST \
                       --header "Authorization: Bearer ${_access_token}" \
                       --header "Content-Type: application/json" \
                       "${_workspace_url}/api/2.0/policies/clusters/create" \
                       -d "$(echo ${payload})")
  policy_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["policy_id"])' 2> /dev/null)
  [ -z "${policy_id}" ] && { echo "${_response}"; exit 1; }
else
  echo -e "Updating the Cluster Policy \"${_policy_name}\"(${policy_id})"
  payload='{"policy_id": "'${policy_id}'",'${base_payload}'}'
  _response=$(curl -sS --request POST \
                       --header "Authorization: Bearer ${_access_token}" \
                       --header "Content-Type: application/json" \
                       "${_workspace_url}/api/2.0/policies/clusters/edit" \
                       -d "$(echo ${payload})")
  [ "${_response}" != "{}" ] && { echo "${_response}"; exit 1; }
fi

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${policy_id}" ] && echo "##vso[task.setvariable variable=databricksPolicyId;issecret=false]${policy_id}"
fi
