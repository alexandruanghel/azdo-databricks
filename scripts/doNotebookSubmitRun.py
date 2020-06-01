#!/usr/bin/env python

import sys,requests,json

"""
Script that starts a Databricks Job using the Runs submit API
It uses simple positional arguments:
  - adbWorkspaceUrl: the base workspace URL
  - aadAccessToken: an AAD Access Token (can also be PAT)
  - notebookPath: Notebook's path in the Workspace
  - notebookParameters: Notebook's arguments as a JSON String
It returns the run_id as a variable called adbNotebookRunId in the Azure Pipelines format
"""
def main():
  adbWorkspaceUrl = sys.argv[1]
  aadAccessToken = sys.argv[2]
  notebookPath = sys.argv[3]
  notebookParameters = sys.argv[4]

  url = '{0}/api/2.0/jobs/runs/submit'.format(adbWorkspaceUrl.rstrip("/"))
  headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer " + aadAccessToken
  }
  payload = {
    "new_cluster": {
      "num_workers": 1,
      "spark_version": "6.5.x-scala2.11",
      "node_type_id": "Standard_F4s"
    },
    "notebook_task": {
      "notebook_path": notebookPath,
      "base_parameters": json.loads(notebookParameters)
    }
  }
  
  response = requests.post(url = url, headers = headers, json = payload)
  if response.status_code == requests.codes.ok:
    runId = response.json()['run_id']
    print("##vso[task.setvariable variable=adbNotebookRunId;issecret=false]{0}".format(runId))
    return
  else:
    return(response.text)

if __name__ == '__main__':
  sys.exit(main())
