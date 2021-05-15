#!/usr/bin/env bash
#
# Adds a secret to a Key Vault (using 'az keyvault secret set').
# It uses simple positional arguments.
#

# Required parameters
_key_vault_name=${1}
_secret_name=${2}
_secret_value=${3}

# Optional parameters
_years_valid=${4:-"1"}
_credential_description=${5:-"azdo"}

# Local variables
_date="$(date -d "+${_years_valid} years" +%Y-%m-%d'T'%H:%M:%S'Z' 2> /dev/null || date -j -v "+${_years_valid}y" +%Y-%m-%d'T'%H:%M:%S'Z' 2> /dev/null )"
[ -z "${_date}" ] && exit 1

_usage() {
  echo -e "Usage: ${0} <key_vault_name> <secret_name> <secret_value>"
  exit 1
}

# Parameters check
[ -z "${_key_vault_name}" ] && _usage
[ -z "${_secret_name}" ] && _usage
[ -z "${_secret_value}" ] && _usage

# Use the az cli command to create/update a secret in the Key Vault
echo -e "Storing the secret \"${_secret_name}\"(expiring on \"${_date}\") in Key Vault \"${_key_vault_name}\""
az keyvault secret set --name "${_secret_name}" \
                       --vault-name "${_key_vault_name}" \
                       --value "${_secret_value}" \
                       --description "${_credential_description}" \
                       --expires "${_date}" > /dev/null || exit 1
echo -e "Secret stored in Key Vault"
