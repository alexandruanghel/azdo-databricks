#!/usr/bin/env bash


echo "Getting the Azure AD Tenant Id"
tenantId=$(az account show | python -c 'import sys,json; print(json.load(sys.stdin)["tenantId"])')
[[ -z ${tenantId} ]] && exit 1

# pass the variable
echo "##vso[task.setvariable variable=tenantId;issecret=true]${tenantId}"
