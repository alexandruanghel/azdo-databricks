#!/usr/bin/env python
"""
Python script that starts a Databricks Job using the Runs submit API (https://docs.databricks.com/dev-tools/api/latest/jobs.html#runs-submit).
It uses simple positional arguments.
It returns the run_id as a variable called notebookRunId in the Azure Pipelines format.
"""
import json
import sys

import requests


def main():
    workspace_url = sys.argv[1]
    access_token = sys.argv[2]
    pool_or_node_type_id = sys.argv[3]
    num_workers = int(sys.argv[4])
    spark_version = sys.argv[5]
    notebook_path = sys.argv[6]
    notebook_parameters = sys.argv[7]

    base_url = '{0}/api/2.0'.format(workspace_url.rstrip("/"))
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + access_token
    }
    payload = {
        "new_cluster": {
            "num_workers": num_workers,
            "spark_version": spark_version,
            "instance_pool_id": pool_or_node_type_id
        },
        "notebook_task": {
            "notebook_path": notebook_path,
            "base_parameters": json.loads(notebook_parameters)
        }
    }

    all_node_types = requests.get(url=base_url + '/clusters/list-node-types', headers=headers).json()
    for node_type in all_node_types["node_types"]:
        if pool_or_node_type_id == node_type["node_type_id"]:
            payload["node_type_id"] = pool_or_node_type_id
            payload.pop("instance_pool_id")
            break

    response = requests.post(url=base_url + '/jobs/runs/submit', headers=headers, json=payload)
    if response.status_code == requests.codes.ok:
        run_id = response.json()['run_id']
        print("run_id: {0}".format(run_id))

        # Pass the variables to Azure Pipelines
        print("##vso[task.setvariable variable=notebookRunId;issecret=false]{0}".format(run_id))
        return
    else:
        return response.text


if __name__ == '__main__':
    sys.exit(main())
