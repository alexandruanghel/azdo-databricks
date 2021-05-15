#!/usr/bin/env python
"""
Python script that creates a Databricks Instance Pool using the Instance Pools API (https://docs.databricks.com/dev-tools/api/latest/instance-pools.html).
It uses simple positional arguments.
It returns the Instance Pool ID as a variable called databricksPoolId in the Azure Pipelines format.
"""
import requests
import sys


def main():
    workspace_url = sys.argv[1]
    access_token = sys.argv[2]
    instance_pool_name = sys.argv[3]
    node_type_id = sys.argv[4]
    min_idle_instances = sys.argv[5]
    idle_instance_autotermination_minutes = sys.argv[6]
    preloaded_spark_version = sys.argv[7]
    azure_availability = sys.argv[8]

    base_url = '{0}/api/2.0/instance-pools'.format(workspace_url.rstrip("/"))
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + access_token
    }
    payload = {
        "instance_pool_name": instance_pool_name,
        "node_type_id": node_type_id,
        "min_idle_instances": min_idle_instances,
        "idle_instance_autotermination_minutes": idle_instance_autotermination_minutes,
        "preloaded_spark_versions": [preloaded_spark_version],
        "azure_attributes": {
            "availability": azure_availability
        }
    }

    # Set the spot settings if availability was set to SPOT_AZURE, otherwise set ON_DEMAND
    if payload["azure_attributes"]["availability"] == "SPOT_AZURE":
        payload["azure_attributes"]["spot_bid_max_price"] = -1
    else:
        payload["azure_attributes"]["availability"] = "ON_DEMAND_AZURE"

    url = base_url + '/create'
    all_pools = requests.get(url=base_url + '/list', headers=headers).json()
    if "instance_pools" in all_pools:
        for pool in all_pools["instance_pools"]:
            if instance_pool_name == pool["instance_pool_name"]:
                payload["instance_pool_id"] = pool["instance_pool_id"]
                url = base_url + '/edit'
                break

    response = requests.post(url=url, headers=headers, json=payload)
    if response.status_code == requests.codes.ok:
        if "instance_pool_id" in payload:
            instance_pool_id = payload["instance_pool_id"]
        else:
            instance_pool_id = response.json()['instance_pool_id']

        # Pass the variables to Azure Pipelines
        print("##vso[task.setvariable variable=databricksPoolId;issecret=false]{0}".format(instance_pool_id))
        return
    else:
        return response.text


if __name__ == '__main__':
    sys.exit(main())
