#!/usr/bin/env bash
#
# Builds the core infrastructure using Terraform.
# Variables are loaded from the vars.sh file.
# Only users can run this script as granting admin-consent with a Service Principal is not supported by the az ad cli.
# The user executing this script must be Owner on the Subscription and Global administrator on the AD Tenant.
#

# Debug
#set -x
#export TF_LOG="DEBUG"


### Variables

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_setup_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_scripts_dir=${_setup_script_dir}/../scripts
_python="$(command -v python || command -v python3)"

# Import variables
source "${_setup_script_dir}/vars.sh"

# Required variables
## the Personal Access Token to authenticate to GitHub
AZDO_GITHUB_SERVICE_CONNECTION_PAT=${AZDO_GITHUB_SERVICE_CONNECTION_PAT:-${AZURE_DEVOPS_EXT_GITHUB_PAT}}

## the Azure DevOps organization URL
AZDO_ORG_SERVICE_URL=${AZDO_ORG_SERVICE_URL:-${AZURE_DEVOPS_ORG_URL}}

## the Azure DevOps organization Personal Access Token
AZDO_PERSONAL_ACCESS_TOKEN=${AZDO_PERSONAL_ACCESS_TOKEN:-${AZURE_DEVOPS_EXT_PAT}}

# Check the required variables
if [ -z "${AZDO_GITHUB_SERVICE_CONNECTION_PAT}" ]; then
  echo "ERROR: The GitHub PAT token was not defined"
  echo "       Either AZURE_DEVOPS_EXT_GITHUB_PAT or AZDO_GITHUB_SERVICE_CONNECTION_PAT variables must be set"
  exit 1
else
  export AZDO_GITHUB_SERVICE_CONNECTION_PAT
fi
if [ -z "${AZDO_ORG_SERVICE_URL}" ]; then
  echo "ERROR: The Azure DevOps organization URL was not defined"
  echo "       Either AZURE_DEVOPS_ORG_URL or AZDO_ORG_SERVICE_URL variables must be set"
  exit 1
else
  export AZDO_ORG_SERVICE_URL
fi
if [ -z "${AZDO_PERSONAL_ACCESS_TOKEN}" ]; then
  echo "ERROR: The Azure DevOps organization Personal Access Token was not defined"
  echo "       Either AZURE_DEVOPS_EXT_PAT or AZDO_PERSONAL_ACCESS_TOKEN variables must be set"
  exit 1
else
  export AZDO_PERSONAL_ACCESS_TOKEN
fi

# Make sure the current Azure CLI login works (using a Service Principal is not supported for this)
echo -e "Checking the existing Azure Authentication\n----------------------"
az_account=$(az account show)
if [ -z "${az_account}" ]; then
  echo -e "ERROR: Authenticating using the Azure CLI as a User is required for this setup"
  echo -e "       Granting admin-consent with a Service Principal is not supported by the az ad cli"
  echo -e "       This is due to https://github.com/Azure/azure-cli/issues/12137"
  echo -e "       Please run 'az login' with a directory administrator User Principal"
  exit 1
fi
user_type=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["user"]["type"])')
user_name=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["user"]["name"])')
[ -z "${user_type}" ] || [ -z "${user_name}" ] && exit 1
if [ "${user_type}" == "servicePrincipal" ]; then
  echo -e "ERROR: Authenticating using the Azure CLI is only supported as a User (not a Service Principal)"
  echo -e "       Please run 'az login' with a directory administrator User Principal"
  exit 1
else
  echo -e "Will use the current Azure CLI login (\"${user_name}\") to authenticate to Azure RM"
fi

# Set the Subscription
if [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
  echo -e "Setting the active subscription to \"${ARM_SUBSCRIPTION_ID}\""
  az account set --subscription "${ARM_SUBSCRIPTION_ID}" || exit 1
fi
echo


### Run Terraform to build the core infrastructure
echo
echo -e "Building the core infrastructure with Terraform\n----------------------------------------------\n"
source "${_scripts_dir}/terraform_azure.sh" apply "${_setup_script_dir}/terraform" -parallelism=3 "$@" -auto-approve
echo
