#!/usr/bin/env bash

### required parameters
adbWorkspaceUrl=$1
aadAccessToken=$2


echo -e "\nShow my user\n------------------"
curl -sS --request GET --header "Authorization: Bearer ${aadAccessToken}" "${adbWorkspaceUrl}/api/2.0/preview/scim/v2/Me" | python -m json.tool

echo -e "\nList all users\n------------------"
curl -sS --request GET --header "Authorization: Bearer ${aadAccessToken}" "${adbWorkspaceUrl}/api/2.0/preview/scim/v2/Users" | python -m json.tool

echo -e "\nList all groups\n------------------"
curl -sS --request GET --header "Authorization: Bearer ${aadAccessToken}" "${adbWorkspaceUrl}/api/2.0/preview/scim/v2/Groups" | python -m json.tool

echo -e "\nList all service principals\n------------------"
curl -sS --request GET --header "Authorization: Bearer ${aadAccessToken}" "${adbWorkspaceUrl}/api/2.0/preview/scim/v2/ServicePrincipals" | python -m json.tool || true
