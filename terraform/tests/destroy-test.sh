#!/usr/bin/env bash
#
# Destroys a test by running terraform destroy.
#

# Debug
#set -x
#export TF_LOG="DEBUG"

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath)"
_this_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_scripts_dir=${_this_script_dir}/../../scripts

# Run test
source "${_scripts_dir}/terraform_azure.sh" destroy "$@" -var-file="${_this_script_dir}/test.tfvars" -auto-approve
echo
