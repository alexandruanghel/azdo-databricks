#!/usr/bin/env bash

### required parameters
storageAccountName=$1
spObjectId=$2


echo -e "Getting the Resources Id of storage account ${storageAccountName}"
storageAccountId=$(az storage account show -n ${storageAccountName} | python -c 'import sys,json; print(json.load(sys.stdin)["id"])')
[[ -z ${storageAccountId} ]] && exit 1
echo -e "Got the Resource Id: ${storageAccountId}"

echo -e "Assigning Contributor role to object ${spObjectId}"
contributorRoleResponse=$(az role assignment create --assignee-object-id "${spObjectId}" --assignee-principal-type ServicePrincipal --role "Contributor" --scope "${storageAccountId}")
[[ -z ${contributorRoleResponse} ]] && exit 1

echo -e "Assigning Storage Blob Data Contributor role to object ${spObjectId}"
blobRoleResponse=$(az role assignment create --assignee-object-id "${spObjectId}" --assignee-principal-type ServicePrincipal --role "Storage Blob Data Contributor" --scope "${storageAccountId}")
[[ -z ${blobRoleResponse} ]] && exit 1

echo -e "Roles have been assigned"
