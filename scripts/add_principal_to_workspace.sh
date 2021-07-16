#!/usr/bin/env bash
#
# Adds a principal to a Databricks workspace using the SCIM API (https://docs.databricks.com/dev-tools/api/latest/scim/index.html).
# It can add a normal user or a service principal.
# It uses simple positional arguments.
# Returns the principal id as a variable called databricksPrincipalId in the Azure Pipelines format.
#

# Required parameters
_workspace_url=${1}
_access_token=${2}
_principal_type=${3}
_principal=${4}
_display_name=${5}

# Local variables
_python="$(command -v python || command -v python3)"

_usage() {
  echo -e "Usage: ${0} <workspace_url> <access_token> [user, service_principal] <principal> <display_name> [entitlements]"
  exit 1
}

# Parameters check
[ -z "${_workspace_url}" ] && _usage
[ -z "${_access_token}" ] && _usage
[ -z "${_principal_type}" ] && _usage
[ -z "${_principal}" ] && _usage
[ -z "${_display_name}" ] && _display_name=${_principal}

# Get the optional entitlements
entitlements=""
for e in $(seq 5 "$#")
do
  eval entitlement='$'${e}
  entitlements=${entitlements}" ${entitlement}"
done

# Set the base payload
base_payload='
  "displayName":"'${_display_name}'",
  "entitlements":[
'$(
  for last in ${entitlements}; do true; done
  for entitlement in ${entitlements}
  do
    echo '{ "value":"'"${entitlement}"'" }'"$([ "${entitlement}" != "${last}" ] && echo ',')"''

  done
)'
  ]
'

# Update the payload with Principal specifics (different schema between a user and a service principal)
if [ "${_principal_type}" == "service_principal" ] || [ "$(echo "${_principal_type}" | tr '[:upper:]' '[:lower:]')" == "serviceprincipal" ]; then
  payload='
  {
    "schemas":[ "urn:ietf:params:scim:schemas:core:2.0:ServicePrincipal" ],
    "applicationId":"'${_principal}'",
    '${base_payload}'
  }
  '
  _scim_api="ServicePrincipals"
  _scim_filter="applicationId"
elif [ "$(echo "${_principal_type}" | tr '[:upper:]' '[:lower:]')" == "user" ]; then
  payload='
  {
    "schemas":[ "urn:ietf:params:scim:schemas:core:2.0:User" ],
    "userName":"'${_principal}'",
    '${base_payload}'
  }
  '
  _scim_api="Users"
  _scim_filter="userName"
else
  _usage
fi

# Check if the Principal already exists
echo -e "Checking the Principal \"${_principal}\" in workspace \"${_workspace_url}\""
_response=$(curl -sS --request GET \
                     --header "Authorization: Bearer ${_access_token}" \
                     --header "Accept: application/scim+json" \
                     "${_workspace_url}/api/2.0/preview/scim/v2/${_scim_api}?filter=${_scim_filter}+eq+${_principal}")
principal_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["Resources"][0]["id"])' 2> /dev/null)

# Add the Principal (or updates if it already exists) using the SCIM API
if [ -z "${principal_id}" ]; then
  echo -e "Adding the Principal \"${_principal}\""
  _response=$(curl -sS --request POST \
                       --header "Authorization: Bearer ${_access_token}" \
                       --header "Content-Type: application/scim+json" \
                       "${_workspace_url}/api/2.0/preview/scim/v2/${_scim_api}" \
                       -d "${payload}")
  principal_id=$(echo "${_response}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["id"])')
  [ -z "${principal_id}" ] && { echo "${_response}"; exit 1; }
else
  echo -e "Updating the Principal \"${_principal}\""
  curl -sS --request PUT \
           --header "Authorization: Bearer ${_access_token}" \
           --header "Content-Type: application/scim+json" \
           "${_workspace_url}/api/2.0/preview/scim/v2/${_scim_api}/${principal_id}" \
           -d "$payload" || exit 1
fi

# Pass the variables to Azure Pipelines
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  [ -n "${principal_id}" ] && echo "##vso[task.setvariable variable=databricksPrincipalId]${principal_id}" || exit 1
fi
