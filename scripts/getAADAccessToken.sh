#!/usr/bin/env bash

### required parameters
databricksUniqueId=$1

# optional parameters - if not set it will use Azure DevOps Principal
spClientId=$2
spClientSecret=$3


if [[ -n ${spClientId} ]] && [[ -n ${spClientSecret} ]]
then
  echo "The App Client Id and Secret have been set, trying to log in as ${spClientId}"
  tenantId=$(az account show | python -c 'import sys,json; print(json.load(sys.stdin)["tenantId"])')
  az logout
  az login --service-principal --username ${spClientId} --password ${spClientSecret} --tenant ${tenantId} --allow-no-subscriptions
fi
  
echo "Getting the AAD access token"
aadAccessToken=$(az account get-access-token --resource=${databricksUniqueId} | python -c 'import sys,json; print(json.load(sys.stdin)["accessToken"])')
[[ -z ${aadAccessToken} ]] && exit 1
echo "Got the AAD access token"

# pass the variables
echo "##vso[task.setvariable variable=aadAccessToken;issecret=true]${aadAccessToken}"
