#!/usr/bin/env bash
#
# Creates an Azure Service Principal (using 'az ad sp create-for-rbac').
# It uses simple positional arguments.
# Returns the service principal client id as a variable called spClientId in the Azure Pipelines format.
# Returns the service principal object id as a variable called spObjectId in the Azure Pipelines format.
# Returns the service principal client secret as a variable called spClientSecret in the Azure Pipelines format.
#

# Required parameters
_sp_registration_name=${1}

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <sp_registration_name>"
  exit 1
}

# Parameters check
[ -z "${_sp_registration_name}" ] && _usage

# Create the Service Principal
echo -e "Creating a Service Principal named \"${_sp_registration_name}\""
_response=$(az ad sp create-for-rbac --name "${_sp_registration_name}")
[ -z "${_response}" ] && exit 1

# Extract the Service Principal Client ID from the response
echo -e "Extracting the Service Principal Client ID and Client Secret from the JSON response"
sp_client_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["appId"])')
[ -z "${sp_client_id}" ] && { echo "${_response}"; exit 1; }
echo -e "Got the Client ID: \"${sp_client_id}\""

# Extract the Service Principal Secret from the response
sp_client_secret=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["password"])')
[ -z "${sp_client_secret}" ] && exit 1
echo -e "Got the Client Secret"

# Get the Object ID of the Service Principal
source "${_script_dir}/get_object_details.sh" "${sp_client_id}"
sp_object_id=${object_id}

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${sp_client_id}" ] && echo "##vso[task.setvariable variable=spClientId;issecret=false]${sp_client_id}" || exit 1
  [ -n "${sp_object_id}" ] && echo "##vso[task.setvariable variable=spObjectId;issecret=false]${sp_object_id}" || exit 1
  [ -n "${sp_client_secret}" ] && echo "##vso[task.setvariable variable=spClientSecret;issecret=true]${sp_client_secret}" || exit 1
fi
