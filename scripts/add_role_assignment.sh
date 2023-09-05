#!/usr/bin/env bash
#
# Creates a new Azure role assignment for a user, group, or service principal (using 'az role assignment').
# It uses simple positional arguments.
#

# Required parameters
_role_name=${1}
_principal_id=${2}
_resource_id=${3}

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
 _script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")

_usage() {
  echo -e "Usage: ${0} <role_name> <principal_id> <resource_id>"
  exit 1
}

# Parameters check
[ -z "${_role_name}" ] && _usage
[ -z "${_principal_id}" ] && _usage
[ -z "${_resource_id}" ] && _usage

# Get the Object details
source "${_script_dir}/get_object_details.sh" "${_principal_id}"
object_id=${object_id}
object_type=${object_type}

# Get the Resource ID
if [[ "${_resource_id}" =~ "/subscriptions" ]]; then
  resource_scope="${_resource_id}"
else
  echo -e "Getting the scope for RG \"${_resource_id}\""
  resource_scope=$(az group show --name "${_resource_id}" --query id --output tsv)
  [ -z "${resource_scope}" ] && exit 1
fi

# Use the az cli command to assign the role on the resource
echo -e "Assigning the \"${_role_name}\" role to \"${_principal_id}\" on the Resource \"${resource_scope}\""
if ! az role assignment create --role "${_role_name}" \
                               --assignee-object-id "${object_id}" \
                               --assignee-principal-type "${object_type}" \
                               --scope "${resource_scope}" \
                               > /dev/null; then
  echo -e "ERROR: Failed to assign the \"${_role_name}\" role on \"${_resource_id}\""
  exit 1
else
  echo -e "\"${_role_name}\" role successfully assigned on \"${_resource_id}\""
fi
