#!/usr/bin/env bash

### required parameters
keyVaultName=$1
spObjectId=$2


echo -e "Adding a read-only policy for Principal ${spObjectId} to Key Vault ${keyVaultName}"
az keyvault set-policy --name ${keyVaultName} --object-id ${spObjectId} --secret-permissions get list || exit 1
