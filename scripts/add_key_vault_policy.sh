#!/usr/bin/env bash
#
# Adds an access policy to a Key Vault (using 'az keyvault set-policy').
# It uses simple positional arguments.
#

# Required parameters
_key_vault_name=${1}
_sp_client_id=${2}

# Optional parameters
_secret_permissions=${3:-"get list"}

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")

_usage() {
  echo -e "Usage: ${0} <key_vault_name> <sp_client_id> [secret_permissions]"
  exit 1
}

# Parameters check
[ -z "${_key_vault_name}" ] && _usage
[ -z "${_sp_client_id}" ] && _usage

# Get the Object ID of Service Principal
source "${_script_dir}/get_object_details.sh" "${_sp_client_id}"
sp_object_id=${object_id}

# Use the az cli command to add the policy to the Key Vault
echo -e "Adding a read-only policy for Service Principal ${_sp_client_id} to Key Vault ${_key_vault_name}"
az keyvault set-policy --name "${_key_vault_name}" \
                       --object-id "${sp_object_id}" \
                       --secret-permissions ${_secret_permissions} || exit 1
