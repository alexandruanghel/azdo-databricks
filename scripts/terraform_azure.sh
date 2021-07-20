#!/usr/bin/env bash
#
# Runs all Terraform commands on a directory.
# Can use a local or remote azurerm backend depending on environment variables.
#

# Debug
#set -x
#export TF_LOG="DEBUG"

# Local variables
_python="$(command -v python || command -v python3)"

# Environment variables
## set these to authenticate using a Service Principal and a Client Secret instead of the current Azure CLI login
export ARM_CLIENT_ID=${ARM_CLIENT_ID:-}
export ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET:-}
export ARM_TENANT_ID=${ARM_TENANT_ID:-}
export ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID:-}

## set these to use a remote azurerm backend
export TF_RESOURCE_GROUP_NAME=${TF_RESOURCE_GROUP_NAME:-}
export TF_STORAGE_ACCOUNT_NAME=${TF_STORAGE_ACCOUNT_NAME:-}
export TF_CONTAINER_NAME=${TF_CONTAINER_NAME:-}
export TF_KEY=${TF_KEY:-}

_usage() {
  echo "Usage: ${0} {apply|destroy} path"
  exit 1
}

_check_auth() {
  # Check the existing Azure Authentication
  echo -e "Checking the existing Azure Authentication\n----------------------"
  if [ -n "${ARM_CLIENT_ID}" ] && [ -n "${ARM_CLIENT_SECRET}" ] && [ -n "${ARM_TENANT_ID}" ] && [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
    echo -e "Will use a Service Principal (\"${ARM_CLIENT_ID}\") to authenticate to Azure RM"
  else
    az_account=$(az account show)
    [ -z "${az_account}" ] && exit 1
    user_type=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["user"]["type"])')
    user_name=$(echo "${az_account}" | ${_python} -c 'import sys,json; print(json.load(sys.stdin)["user"]["name"])')
    [ -z "${user_type}" ] || [ -z "${user_name}" ] && exit 1
    if [ "${user_type}" == "servicePrincipal" ]; then
      echo -e "ERROR: Authenticating using the Azure CLI is only supported as a User (not a Service Principal)"
      echo -e "       To authenticate as a Service Principal, set the following environment variables:"
      echo -e "                                       ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID"
      exit 1
    else
      echo -e "Will use the current Azure CLI login (\"${user_name}\") to authenticate to Azure RM"
    fi

    # Set the Subscription
    if [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
      echo -e "Setting the active subscription to \"${ARM_SUBSCRIPTION_ID}\""
      az account set --subscription "${ARM_SUBSCRIPTION_ID}" || exit 1
    fi
  fi
}

_cd_dir() {
  # Go to the Terraform dir
  local tf_path="${1}"
  if [ -z "${tf_path}" ]; then
    echo "ERROR: No path given"
    _usage
    exit 1
  fi
  if [ -d "${tf_path}" ]; then
    cd "${tf_path}" || exit 1
  else
    echo -e "ERROR: Terraform folder ${tf_path} doesn't exist"
    exit 1
  fi
}

_apply() {
  # Go to the Terraform dir
  _cd_dir "${1}"

  # Shift input parameters by 1
  shift 1

  # Run terraform init
  if [ -n "${TF_RESOURCE_GROUP_NAME}" ] && [ -n "${TF_STORAGE_ACCOUNT_NAME}" ] && [ -n "${TF_CONTAINER_NAME}" ] && [ -n "${TF_KEY}" ]
  then
    echo -e "Running terraform init with azurerm remote backend\n----------------------"
    terraform init \
      -backend-config="resource_group_name=${TF_RESOURCE_GROUP_NAME}" \
      -backend-config="storage_account_name=${TF_STORAGE_ACCOUNT_NAME}" \
      -backend-config="container_name=${TF_CONTAINER_NAME}" \
      -backend-config="key=${TF_KEY}" \
      -upgrade=true || exit 1
  else
    echo -e "Running terraform init with local backend\n----------------------"
    terraform init -upgrade=true || exit 1
  fi

  # Run terraform validate
  echo -e "\nRunning terraform validate\n----------------------"
  terraform validate || exit 1

  # Run terraform plan (and remove -auto-approve from the list of arguments)
  echo -e "\nRunning terraform plan\n----------------------"
  plan_args="$(for arg in "$@"; do echo "${arg}" | grep -v "\-auto-approve"; done)"
  terraform plan ${plan_args} -out=tfplan.out || exit 1

  # Run terraform apply (and remove -var-file from the list of arguments since it's contained in the plan)
  echo -e "\nRunning terraform apply\n----------------------"
  apply_args="$(for arg in "$@"; do echo "${arg}" | grep -v "\-var"; done)"
  terraform apply ${apply_args} tfplan.out || exit 1
  [ -e "tfplan.out" ] && unlink "tfplan.out"
  echo -n
}

_destroy() {
  # Go to the Terraform dir
  _cd_dir "${1}"

  # Shift input parameters by 1
  shift 1

  # Run terraform destroy
  echo -e "Running terraform destroy\n----------------------"
  terraform destroy "$@" || exit 1

  # Clean terraform files
  echo -e "\nCleaning terraform files\n----------------------"
  echo -e "Removing .terraform" && [ -e ".terraform" ] && rm -rf ".terraform"
  echo -e "Removing .terraform.lock.hcl" && [ -e ".terraform.lock.hcl" ] && unlink ".terraform.lock.hcl"
  echo -e "Removing terraform.tfstate" && [ -e "terraform.tfstate" ] && unlink "terraform.tfstate"
  echo -e "Removing terraform.tfstate.backup" && [ -e "terraform.tfstate.backup" ] && unlink "terraform.tfstate.backup"
  echo -e "Removing crash.log" && [ -e "crash.log" ] && unlink "crash.log"
  echo -e "Removing tfplan.out" && [ -e "tfplan.out" ] && unlink "tfplan.out"
  echo -n
}

case "${1}" in
  apply)
    _check_auth
    echo
    shift 1
    _apply "$@"
    ;;
  destroy)
    _check_auth
    echo
    shift 1
    _destroy "$@"
    ;;
  *)
    _usage
    ;;
esac
