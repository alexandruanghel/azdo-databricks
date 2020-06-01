#!/usr/bin/env python

import sys,requests,json,time

"""
Script that waits for a Databricks Job to complete using the Runs get output API
It waits for a maximum of 10 minutes by default
It prints the notebook_output if one exists (when it's a Notebook Job)
It uses simple positional arguments:
  - adbWorkspaceUrl: the base workspace URL
  - aadAccessToken: an AAD Access Token (can also be PAT)
  - adbNotebookRunId: the run_id of the Job
"""
def main():
  adbWorkspaceUrl = sys.argv[1]
  aadAccessToken = sys.argv[2]
  adbNotebookRunId = sys.argv[3]
  adbNotebookRunWaitTime = 600 #10 minutes

  url = '{0}/api/2.0/jobs/runs/get-output?run_id={1}'.format(adbWorkspaceUrl.rstrip("/"), adbNotebookRunId)
  headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer " + aadAccessToken
  }

  currentRunTime=0
  while currentRunTime < adbNotebookRunWaitTime:
    response = requests.get(url = url, headers = headers)
    if response.status_code == requests.codes.ok:
      responseJson = response.json()
      runState = responseJson["metadata"]["state"]["life_cycle_state"]
      if runState == "INTERNAL_ERROR" or runState == "SKIPPED":
        return(runState)
      if runState == "TERMINATED":
        resultState = responseJson["metadata"]["state"]["result_state"]
        if resultState != "SUCCESS":
          return(resultState)
        if "notebook_output" in responseJson.keys():
          resultOutput = responseJson["notebook_output"]["result"]
          print(resultOutput)
        return
      currentRunTime += 10
      print("Current state: " + str(runState) + ". Sleeping for 10 seconds. Remaining: " + str(adbNotebookRunWaitTime - currentRunTime) + " seconds." + "\n")
      time.sleep(10)
    else:
      return("Error " + str(response.status_code) + ":\n" + response.text)
  else:
    return(response.text)

if __name__ == '__main__':
  sys.exit(main())
