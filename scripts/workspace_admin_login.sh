#!/usr/bin/env bash
#
# Logs into a Databricks workspace as an admin (https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token).
#

# Required parameters
_resource_group_name=${1}
_workspace_name=${2}
_sp_client_id=${3:-${ARM_CLIENT_ID:-${servicePrincipalId}}}
_sp_client_secret=${4:-${ARM_CLIENT_SECRET:-${servicePrincipalKey}}}
_tenant_id=${5:-${ARM_TENANT_ID:-${tenantId}}}
_databricks_unique_id='2ff814a6-3304-4ab8-85cb-cd0e6f879c1d'

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <resource_group_name> <workspace_name> <sp_client_id> <sp_client_secret> <tenant_id>"
  exit 1
}

# Parameters check
[ -z "${_resource_group_name}" ] && _usage
[ -z "${_workspace_name}" ] && _usage
[ -z "${_sp_client_id}" ] && _usage
[ -z "${_sp_client_secret}" ] && _usage
[ -z "${_tenant_id}" ] && _usage

# Get the management token
echo -e "Getting the Management Token"
_response=$(curl -sS --request GET \
                     --header "Content-Type: application/x-www-form-urlencoded" \
                     --data "grant_type=client_credentials&client_id=${_sp_client_id}&resource=https://management.core.windows.net/&client_secret=${_sp_client_secret}" \
                     "https://login.microsoftonline.com/${_tenant_id}/oauth2/token")

management_token=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["access_token"])' )
[ -z "${management_token}" ] && { echo "${_response}"; exit 1; }
echo -e "Got the Management Token"
echo

# Login with the Service Principal
echo -e "Logging in to Azure as ${_sp_client_id}"
az login --service-principal --username "${_sp_client_id}" --password "${_sp_client_secret}" --tenant "${_tenant_id}" --allow-no-subscriptions > /dev/null || exit 1
echo

# Get the AAD Access Token over the Databricks resource
echo -e "Getting the AAD Access Token"
access_token=$(az account get-access-token --resource="${_databricks_unique_id}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["accessToken"])')
[ -z "${access_token}" ] && exit 1
echo -e "Got the AAD access token"
echo

# Get the workspace details with az cli
echo -e "Getting the URL of Databricks workspace ${_workspace_name} from Resource Group ${_resource_group_name}"
_response=$(az resource show --name "${_workspace_name}" \
                             --resource-type "Microsoft.Databricks/workspaces" \
                             --resource-group "${_resource_group_name}" \
                             --output json)
[ -z "${_response}" ] && exit 1

# Get the workspace URL from response
workspace_hostname=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["properties"]["workspaceUrl"])')
[ -z "${workspace_hostname}" ] && { echo "${_response}"; exit 1; }
workspace_url="https://${workspace_hostname}"
echo -e "Got the URL: ${workspace_url}"

# Get the workspace Resource ID from response
workspace_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])')
[ -z "${workspace_id}" ] && { echo "${_response}"; exit 1; }
echo -e "Got the Databricks workspace ID: ${workspace_id}"
echo

# First login with the new token
echo -e "Checking first login"
_user_name=$(curl -sS --request GET \
                      --header "Authorization: Bearer ${access_token}" \
                      --header "X-Databricks-Azure-SP-Management-Token: ${management_token}" \
                      --header "X-Databricks-Azure-Workspace-Resource-Id: ${workspace_id}" \
                      "${workspace_url}/api/2.0/preview/scim/v2/Me" \
                      | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["userName"])')
[ -z "${_user_name}" ] && exit 1
echo -e "Logged in with user ${_user_name}"
echo

# Get the workspace-conf
echo -e "Getting the workspace-conf"
_workspace_conf=$(curl -sS --request GET \
                           --header "Authorization: Bearer ${access_token}" \
                           --header "X-Databricks-Azure-SP-Management-Token: ${management_token}" \
                           --header "X-Databricks-Azure-Workspace-Resource-Id: ${workspace_id}" \
                           "${workspace_url}/api/2.0/workspace-conf" || exit 1)
echo "${_workspace_conf}" | ${_python} -c 'import sys,json,pprint; pprint.pprint(json.load(sys.stdin))'
echo
