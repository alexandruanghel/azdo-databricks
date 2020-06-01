#!/usr/bin/env bash

### required parameters
adbWorkspaceUrl=$1
aadAccessToken=$2
adbSecretScope=$3
secretName=$4
secretValue=$5


echo && echo -e "Storing the secret ${secretName} to Secret Scope ${adbSecretScope}"
curl -sS --request POST --header "Authorization: Bearer ${aadAccessToken}" --header "Content-Type: application/json" "${adbWorkspaceUrl}/api/2.0/secrets/put" -d '
{
  "scope": "'${adbSecretScope}'",
  "key": "'${secretName}'",
  "string_value": "'${secretValue}'"
}
' | python -c 'import sys,json; print(json.load(sys.stdin)["error_code"])' 2>/dev/null && exit 1 || exit 0
