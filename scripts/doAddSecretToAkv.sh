#!/usr/bin/env bash

### required parameters
keyVaultName=$1
secretName=$2
secretValue=$3


echo -e "Storing the secret ${secretName} in Key Vault ${keyVaultName}"
az keyvault secret set --name ${secretName} --vault-name ${keyVaultName} --value ${secretValue} || exit 1
