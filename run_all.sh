#!/usr/bin/env bash
#
# Runs all:
#  builds the Azure core infrastructure
#  builds the Azure infrastructure for the data pipeline and project
#  bootstraps the Databricks workspace
#  launches an Azure Data Factory data pipeline that uses Databricks
#

# Use Terraform for the entire setup? - if not set it will use Azure CLI and scripts
USE_TERRAFORM=${USE_TERRAFORM:-"yes"}

# Local variables
_realpath() { [[ ${1} == /* ]] && echo "${1}" || echo "${PWD}"/"${1#./}"; }
_realpath="$(command -v realpath || echo _realpath )"
_this_script_dir=$(${_realpath} "$(dirname "${BASH_SOURCE[0]}")")
_wait_time=1800   # 30 minutes

# Import variables
source "${_this_script_dir}/admin/vars.sh" || exit 1

# Run the admin setup
if [ "${USE_TERRAFORM}" = "yes" ] || [ "${USE_TERRAFORM}" = "true" ]; then
  echo -e "Using Terraform (USE_TERRAFORM variable was set to \"${USE_TERRAFORM}\")\n----------------------------------------------"
  echo
  source "${_this_script_dir}/admin/setup-with-terraform.sh"
else
  echo -e "Using ARM templates and Azure CLI scripts (USE_TERRAFORM variable was set to \"${USE_TERRAFORM}\")\n----------------------------------------------"
  echo
  USE_TERRAFORM="no" source "${_this_script_dir}/admin/setup-with-azure-cli.sh"
fi
echo

# Wait until the secret is active
echo -e "Sleeping for 2 minutes to allow enough time for the client secret to propagate\n----------------------------------------------"
sleep 120
echo

# Install the Azure DevOps cli extension
az extension add --name azure-devops 2> /dev/null || { az extension add --name azure-devops --debug; exit 1; }

# Run the infra pipeline
echo -e "Running the infra pipeline \"${AZURE_DEVOPS_INFRA_PIPELINE_NAME}\"\n----------------------------------------------"
_run_id_infra=$(az pipelines run --name "${AZURE_DEVOPS_INFRA_PIPELINE_NAME}" --organization "${AZURE_DEVOPS_ORG_URL}" --project "${AZURE_DEVOPS_PROJECT_NAME}" --query id)
[ -z "${_run_id_infra}" ] && exit 1
echo

echo -e "Waiting for run_id \"${_run_id_infra}\" of pipeline \"${AZURE_DEVOPS_INFRA_PIPELINE_NAME}\" to finish\n----------------------"
timer=0
while [ ${timer} -lt ${_wait_time} ]; do
  _run_status=$(az pipelines runs show --id "${_run_id_infra}" --organization "${AZURE_DEVOPS_ORG_URL}" --project "${AZURE_DEVOPS_PROJECT_NAME}" --query result || echo ERROR)
  [ -n "${_run_status}" ] && break
  echo -e "Sleeping for 30 seconds"
  sleep 30 && timer=$((timer+30)) && (exit 1)
done || { echo "ERROR: Timed out waiting"; exit 1; }
if [ "${_run_status}" != "\"succeeded\"" ]; then
  echo -e "Run \"${_run_id_infra}\" of pipeline \"${AZURE_DEVOPS_INFRA_PIPELINE_NAME}\" was not successful, status was ${_run_status}"
  exit 1
else
  echo -e "Run status was ${_run_status}"
fi
echo

# Run the data pipeline
echo -e "Running the data pipeline \"${AZURE_DEVOPS_DATA_PIPELINE_NAME}\"\n----------------------------------------------"
_adf_updated_after="$(date -u +%Y-%m-%d'T'%H:%M:%S'Z')"
_azdo_run_id_data=$(az pipelines run --name "${AZURE_DEVOPS_DATA_PIPELINE_NAME}" --organization "${AZURE_DEVOPS_ORG_URL}" --project "${AZURE_DEVOPS_PROJECT_NAME}" --query id)
[ -z "${_azdo_run_id_data}" ] && exit 1
echo

echo -e "Waiting for run_id \"${_azdo_run_id_data}\" of pipeline \"${AZURE_DEVOPS_DATA_PIPELINE_NAME}\" to finish\n----------------------"
timer=0
while [ ${timer} -lt ${_wait_time} ]; do
  _azdo_run_status=$(az pipelines runs show --id "${_azdo_run_id_data}" --organization "${AZURE_DEVOPS_ORG_URL}" --project "${AZURE_DEVOPS_PROJECT_NAME}" --query result || echo ERROR)
  [ -n "${_azdo_run_status}" ] && break
  echo -e "Sleeping for 30 seconds"
  sleep 30 && timer=$((timer+30)) && (exit 1)
done || { echo "ERROR: Timed out waiting"; exit 1; }
if [ "${_azdo_run_status}" != "\"succeeded\"" ]; then
  echo -e "Run \"${_azdo_run_id_data}\" of pipeline \"${AZURE_DEVOPS_DATA_PIPELINE_NAME}\" was not successful, status was ${_azdo_run_status}"
  exit 1
else
  echo -e "Run status was ${_azdo_run_status}"

  # Optionally try to get Data Factory run details
  _adf_updated_before="$(date -u +%Y-%m-%d'T'%H:%M:%S'Z')"
  _data_factory_name="$(grep DATA_FACTORY_NAME "${_this_script_dir}/pipelines/vars.yml" | cut -d':' -f2 | cut -d'#' -f1 | tr -d "'" | tr -d '"' | tr -d '[:space:]')"
  [ -z "${_data_factory_name}" ] && { echo "Could not get the Data Factory name"; exit 1; }

  # Install the Azure Data Factory cli extension
  az extension add --name datafactory 2> /dev/null || { az extension add --name datafactory --debug; exit 1; }
  # Get the data factory resource id
  _adf_id=$(az datafactory show --name "${_data_factory_name}" --resource-group "${DATABRICKS_RESOURCE_GROUP_NAME}" --query id 2> /dev/null | tr -d '"')
  [ -z "${_adf_id}" ] && { echo "Could not get the Data Factory resource id"; exit 1; }

  # Get the data pipeline run id
  _adf_run_id=$(az datafactory pipeline-run query-by-factory --factory-name "${_data_factory_name}" --resource-group "${DATABRICKS_RESOURCE_GROUP_NAME}" --last-updated-after "${_adf_updated_after}" --last-updated-before "${_adf_updated_before}" --query value[0].runId 2> /dev/null | tr -d '"')
  [ -z "${_adf_run_id}" ] && { echo "Could not get the Data Factory pipeline run id"; exit 1; }

  _adf_run_url="https://adf.azure.com/monitoring/pipelineruns/${_adf_run_id}?factory=$_adf_id"

  echo -e "The Data Factory pipeline run id is: \"${_adf_run_id}\""
  echo -e "Check the status of the run here: \"${_adf_run_url}\""
fi
echo
