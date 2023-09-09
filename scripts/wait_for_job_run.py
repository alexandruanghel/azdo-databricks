#!/usr/bin/env python
"""
Python script that waits for a Databricks Job to complete using the Runs get output API (https://docs.databricks.com/dev-tools/api/latest/jobs.html#runs-get-output).
It uses simple positional arguments.
It waits for a maximum of 15 minutes by default.
It prints the notebook_output if one exists.
"""
import sys
import time

import requests


def main():
    workspace_url = sys.argv[1]
    access_token = sys.argv[2]
    run_id = sys.argv[3]
    run_wait_time = 900  # 15 minutes

    url = '{0}/api/2.0/jobs/runs/get-output?run_id={1}'.format(workspace_url.rstrip("/"), run_id)
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + access_token
    }

    current_run_time = 0
    response = requests.get(url=url, headers=headers)
    while current_run_time < run_wait_time:
        if response.status_code == requests.codes.ok:
            response_json = response.json()
            run_state = response_json["metadata"]["state"]["life_cycle_state"]
            if run_state == "INTERNAL_ERROR" or run_state == "SKIPPED":
                return run_state
            if run_state == "TERMINATED":
                result_state = response_json["metadata"]["state"]["result_state"]
                if result_state != "SUCCESS":
                    return result_state
                if "notebook_output" in response_json.keys():
                    print(response_json["notebook_output"]["result"])
                return
            current_run_time += 10
            print("Current state: " + str(run_state) + ". Sleeping for 10 seconds")
            print("Remaining: " + str(run_wait_time - current_run_time) + " seconds" + "\n")
            time.sleep(10)

            response = requests.get(url=url, headers=headers)
        else:
            return "Error " + str(response.status_code) + ":\n" + response.text
    else:
        return response.text


if __name__ == '__main__':
    sys.exit(main())
