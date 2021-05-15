#!/usr/bin/env bash
#
# Creates a file system for Azure Data Lake Storage Gen2 account (using 'az storage fs').
# It uses simple positional arguments.
#

# Required parameters
_storage_account_name=${1}
_storage_filesystem_name=${2}

_usage() {
  echo -e "Usage: ${0} <storage_account_name> <storage_filesystem_name>"
  exit 1
}

# Parameters check
[ -z "${_storage_account_name}" ] && _usage
[ -z "${_storage_filesystem_name}" ] && _usage

# Use the az cli command to create the ADLS Filesystem
echo -e "Creating the Filesystem \"${_storage_filesystem_name}\" in the Storage Account \"${_storage_account_name}\""
_filesystem=$(az storage fs show --account-name "${_storage_account_name}" \
                                 --name "${_storage_filesystem_name}" \
                                 --auth-mode login --timeout 30)

if [ -z "${_filesystem}" ] && ! az storage fs create --account-name "${_storage_account_name}" \
                                 --name "${_storage_filesystem_name}" \
                                 --auth-mode login --timeout 30 > /dev/null; then
  echo -e "ERROR: Filesystem \"${_storage_filesystem_name}\" was not created successfully"
  exit 1
else
  echo -e "Filesystem \"${_storage_filesystem_name}\" created successfully or already exists"
fi
