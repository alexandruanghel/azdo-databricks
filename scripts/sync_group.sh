#!/usr/bin/env bash
#
# Syncs an Azure Active Directory Group to a Databricks workspace using the SCIM API (https://docs.databricks.com/dev-tools/api/latest/scim/index.html).
# The group can contain users or service principals.
# It uses simple positional arguments.
# Returns the Databricks Group ID as a variable called databricksGroupId in the Azure Pipelines format.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_group_name=${3}

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> <group_name>"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_group_name}" ] && _usage

# Use the az cli command to get the Group members from Azure AD
echo -e "Checking the Group \"${_group_name}\" in the Azure AD Tenant"
group_members=$(az ad group member list --group "${_group_name}" \
                                        --query "[].[objectType, userPrincipalName || appId, displayName || appDisplayName ]" \
                                        --output tsv)

# Add the Group members as new users to the Databricks workspace
IFS=$'\n'
for member in ${group_members}; do
  IFS=$'\t'
  # ${member} will contain 3 tab separated strings as retrieved from Azure: principal_type principal_name display_name
  source "${_script_dir}/add_principal_to_workspace.sh" "${_workspace_url}" "${_access_token}" ${member}
  new_members="${principal_id} ${new_members}"
done

# Set the payload
IFS=' '
payload='
{
  "schemas":[ "urn:ietf:params:scim:schemas:core:2.0:Group" ],
  "displayName":"'${_group_name}'",
  "members":[
'$(
  for last in ${new_members}; do true; done
  for member in ${new_members}
  do
    echo '{ "value":"'"${member}"'" }'"$([ "${member}" != "${last}" ] && echo ',')"''

  done
)'
  ]
}
'

# Check if the Group already exists in the Databricks workspace
echo -e "Checking the Group \"${_group_name}\" in workspace \"${_workspace_url}\""
_response=$(curl -sS --request GET \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Accept: application/scim+json" \
                     "${_workspace_url}/api/2.0/preview/scim/v2/Groups?filter=displayName+eq+%22${_group_name// /$'%20'}%22")
group_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["Resources"][0]["id"])' 2> /dev/null)

# Create the Group if it doesn't exit and update the Group otherwise
if [ -z "${group_id}" ]; then
  echo -e "Creating the Group \"${_group_name}\""
  _response=$(curl -sS --request POST \
                       --header "Authorization: Bearer ${_access_token}" \
                       --header "Content-Type: application/scim+json" \
                       "${_workspace_url}/api/2.0/preview/scim/v2/Groups" \
                       -d "${payload}")
else
  echo -e "Updating the Group \"${_group_name}\""
  _response=$(curl -sS --request PUT \
                       --header "Authorization: Bearer ${_access_token}" \
                       --header "Content-Type: application/scim+json" \
                       "${_workspace_url}/api/2.0/preview/scim/v2/Groups/${group_id}" \
                       -d "${payload}")
fi

# Check the response and extract the Databricks Group ID
group_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])')
[ -z "${group_id}" ] && { echo "${_response}"; exit 1; }
echo "Databricks Group ID: ${group_id}"

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${group_id}" ] && echo "##vso[task.setvariable variable=databricksGroupId]${group_id}" || exit 1
fi
