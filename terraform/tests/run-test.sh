#!/usr/bin/env bash
#
# Tests a Terraform module by running Terraform on a test folder
#

# Debug
#set -x
#export TF_LOG="DEBUG"

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_this_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_scripts_dir=${_this_script_dir}/../../scripts

# Run Terraform to build any test dependencies
source "${_scripts_dir}/terraform_azure.sh" apply "$@" -var-file="${_this_script_dir}/test.tfvars" -auto-approve -target=null_resource.test_dependencies || exit 1
echo

# Run test
cd "${_this_script_dir}" || exit 1
source "${_scripts_dir}/terraform_azure.sh" apply "$@" -var-file="${_this_script_dir}/test.tfvars" -auto-approve
echo
