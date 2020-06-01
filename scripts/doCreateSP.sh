#!/usr/bin/env bash

### required parameters
spRegistrationName=$1


echo -e "Creating a Service Principal named ${spRegistrationName}"
newSpResponse=$(az ad sp create-for-rbac --name "${spRegistrationName}" --skip-assignment)
[[ -z ${newSpResponse} ]] && exit 1

echo -e "Getting the Service Principal Client Id and Client Secret from the JSON response"
newSpClientId=$(echo ${newSpResponse} | python -c 'import sys,json; print(json.load(sys.stdin)["appId"])')
[[ -z ${newSpClientId} ]] && exit 1
echo -e "Got the Client Id: ${newSpClientId}"

newSpClientSecret=$(echo ${newSpResponse} | python -c 'import sys,json; print(json.load(sys.stdin)["password"])')
[[ -z ${newSpClientSecret} ]] && exit 1
echo -e "Got the Client Secret"

echo -e "Getting the Object Id of service principal ${newSpClientId}"
newSpObjectId=$(az ad sp show --id ${newSpClientId} | python -c 'import sys,json; print(json.load(sys.stdin)["objectId"])')
[[ -z ${newSpObjectId} ]] && exit 1
echo -e "Got the Object Id: ${newSpObjectId}"


# pass the variables
echo "##vso[task.setvariable variable=newSpClientId;issecret=false]${newSpClientId}"
echo "##vso[task.setvariable variable=newSpObjectId;issecret=false]${newSpObjectId}"
echo "##vso[task.setvariable variable=newSpClientSecret;issecret=true]${newSpClientSecret}"
