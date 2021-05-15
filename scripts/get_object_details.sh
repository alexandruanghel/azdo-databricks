#!/usr/bin/env bash
#
# Retrieves the Azure Object ID of the current az cli login (using 'az ad sp show').
# It can retrieve a normal user or a service principal or a group.
# If an optional argument is used, it will retrieve the Object ID of the value of the argument.
# Returns the object id as a variable called objectId in the Azure Pipelines format.
# Returns the object type as a variable called objectType in the Azure Pipelines format.
#

# Optional parameters - if not set it will use Azure DevOps Principal already logged in
_principal_id=${1}

# Local variables
_python="$(command -v python || command -v python3)"

# Parameters check
if [ -z "${_principal_id}" ]; then
  echo -e "The Principal was not defined, using the cli user"
  az_account=$(az account show)
  [ -z "${az_account}" ] && exit 1

  _principal_id=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["user"]["name"])' 2> /dev/null)
  echo -e "Got the Principal: \"${_principal_id}\""
fi

# Use the az cli command to get the object details
echo -e "Getting the Object ID for \"${_principal_id}\""
timer=0
while [ ${timer} -lt 100 ]; do
  _response=$(az ad sp show --id "${_principal_id}" || az ad user show --id "${_principal_id}" || az ad group show --group "${_principal_id}")
  [ -n "${_response}" ] && break
  echo -e "Principal \"${_principal_id}\" might not be accessible yet, sleeping for 10 seconds"
  sleep 10 && timer=$((timer+10)) && (exit 1)
done || { echo "ERROR: Timed out waiting"; exit 1; }

# Extract the object ID from response
object_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["objectId"])')
[ -z "${object_id}" ] && { echo "${_response}"; exit 1; }
echo -e "Got the Object ID: \"${object_id}\""

# Extract the object type from response
object_type=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["objectType"])')
[ -z "${object_type}" ] && { echo "${_response}"; exit 1; }
echo -e "Got the Object Type: \"${object_type}\""

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${object_id}" ] && echo "##vso[task.setvariable variable=objectId;issecret=false]${object_id}" || exit 1
  [ -n "${object_type}" ] && echo "##vso[task.setvariable variable=objectType;issecret=false]${object_type}" || exit 1
fi
