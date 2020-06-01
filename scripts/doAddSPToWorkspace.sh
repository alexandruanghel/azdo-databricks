#!/usr/bin/env bash

### required parameters
adbWorkspaceUrl=$1
aadAccessToken=$2
spClientId=$3
spRegistrationName=$4


echo -e "Adding the Service Principal ${spRegistrationName}(${spClientId}) to workspace ${adbWorkspaceUrl}"
curl -sS --request POST --header "Authorization: Bearer ${aadAccessToken}" --header "Content-Type: application/scim+json" "${adbWorkspaceUrl}/api/2.0/preview/scim/v2/ServicePrincipals" -d '
{
  "schemas":[
    "urn:ietf:params:scim:schemas:core:2.0:ServicePrincipal"
  ],
  "applicationId":"'${spClientId}'",
  "displayName":"'${spRegistrationName}'",
  "entitlements":[
    {
       "value":"allow-cluster-create"
    },
    {
       "value":"allow-instance-pool-create"
    }
  ]
}
'
