#!/usr/bin/env bash

### required parameters
adbWorkspaceUrl=$1
aadAccessToken=$2
adbSecretScope=$3
spClientId=$4
createSecretScopeNotebookPath=$5


echo && echo -e "Checking if Secret Scope ${adbSecretScope} exists"
curl -sS --request GET --header "Authorization: Bearer ${aadAccessToken}" --header "Content-Type: application/json" "${adbWorkspaceUrl}/api/2.0/secrets/list?scope=${adbSecretScope}" | python -c 'import sys,json; print(json.load(sys.stdin)["error_code"])' 2>/dev/null
if [[ $? -eq 0 ]]
then
  echo && echo -e "Creating Secret Scope ${adbSecretScope}"

  echo && echo -e "Starting a run submit job with the Notebook ${createSecretScopeNotebookPath}"
  adbNotebookRunResponse=$(python $(dirname $0)/doNotebookSubmitRun.py "${adbWorkspaceUrl}" "${aadAccessToken}" "${createSecretScopeNotebookPath}" "{\"secretScope\":\"${adbSecretScope}\"}")
  [[ $? -ne 0 ]] && exit 1
  adbNotebookRunId=$(echo ${adbNotebookRunResponse} | cut -d']' -f2)
  
  echo && echo -e "Waiting for run_id ${adbNotebookRunId}"
  python $(dirname $0)/waitForJobRun.py "${adbWorkspaceUrl}" "${aadAccessToken}" "${adbNotebookRunId}"
  [[ $? -ne 0 ]] && exit 1
else
  echo && echo -e "Secret Scope ${adbSecretScope} already exists"
fi

echo && echo -e "Giving READ permissions to SP ${spClientId} on Secret Scope ${adbSecretScope}"
curl -sS --request POST --header "Authorization: Bearer ${aadAccessToken}" --header "Content-Type: application/json" "${adbWorkspaceUrl}/api/2.0/secrets/acls/put" -d '
{
  "scope": "'${adbSecretScope}'",
  "principal": "'${spClientId}'",
  "permission": "READ"
}
' || exit 1
