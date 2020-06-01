#!/usr/bin/env bash

### required parameters
adbResourceGroup=$1
adbWorkspaceName=$2


echo "Getting the URL of Workspace ${adbWorkspaceName} from Resource Group ${adbResourceGroup}"
adbWorkspaceHostname=$(az resource show -g ${adbResourceGroup} -n ${adbWorkspaceName} --resource-type "Microsoft.Databricks/workspaces" | python -c 'import sys,json; print(json.load(sys.stdin)["properties"]["workspaceUrl"])')
[[ -z ${adbWorkspaceHostname} ]] && exit 1
adbWorkspaceUrl="https://${adbWorkspaceHostname}"
echo "Got the URL: ${adbWorkspaceUrl}"

# pass the variables
echo "##vso[task.setvariable variable=adbWorkspaceUrl;issecret=false]${adbWorkspaceUrl}"
