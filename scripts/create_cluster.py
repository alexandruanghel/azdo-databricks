#!/usr/bin/env python
"""
Python script that creates a Databricks Cluster using the Clusters API (https://docs.databricks.com/dev-tools/api/latest/clusters.html).
It uses simple positional arguments.
It returns the Cluster ID as a variable called databricksClusterId in the Azure Pipelines format.
"""
import sys

import requests


def main():
    workspace_url = sys.argv[1]
    access_token = sys.argv[2]
    cluster_name = sys.argv[3]
    cluster_type = sys.argv[4]
    autotermination_minutes = sys.argv[5]
    spark_version = sys.argv[6]
    pool_or_node_type_id = sys.argv[7]
    num_workers = int(sys.argv[8])
    stop_cluster = True

    max_num_workers = 0
    if len(sys.argv) > 9:
        if len(sys.argv[9]) > 0:
            max_num_workers = int(sys.argv[9])

    base_url = '{0}/api/2.0/clusters'.format(workspace_url.rstrip("/"))
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + access_token
    }
    payload = {
        "cluster_name": cluster_name,
        "spark_version": spark_version,
        "autotermination_minutes": autotermination_minutes,
        "instance_pool_id": pool_or_node_type_id
    }
    if max_num_workers > num_workers:
        payload["autoscale"] = {
            "min_workers": num_workers,
            "max_workers": max_num_workers
        }
    else:
        payload["num_workers"] = num_workers

    if cluster_type.lower() == "credential passthrough":
        payload["spark_conf"] = {
            "spark.databricks.cluster.profile": "serverless",
            "spark.databricks.repl.allowedLanguages": "python,sql",
            "spark.databricks.passthrough.enabled": "true",
            "spark.databricks.pyspark.enableProcessIsolation": "true"
        }

    url = base_url + '/create'
    all_clusters = requests.get(url=base_url + '/list', headers=headers).json()
    if "clusters" in all_clusters:
        for cluster in all_clusters["clusters"]:
            if cluster_name == cluster["cluster_name"]:
                payload["cluster_id"] = cluster["cluster_id"]
                url = base_url + '/edit'
                break
    all_node_types = requests.get(url=base_url + '/list-node-types', headers=headers).json()
    for node_type in all_node_types["node_types"]:
        if pool_or_node_type_id == node_type["node_type_id"]:
            payload["node_type_id"] = pool_or_node_type_id
            payload.pop("instance_pool_id")
            break

    print(payload)
    response = requests.post(url=url, headers=headers, json=payload)
    if response.status_code == requests.codes.ok:
        if "cluster_id" in payload:
            cluster_id = payload["cluster_id"]
        else:
            cluster_id = response.json()['cluster_id']

        # Stop the cluster immediately after creation
        if stop_cluster:
            requests.post(url=base_url + '/delete', headers=headers, data='{"cluster_id": "' + cluster_id + '"}')

        # Pass the variables to Azure Pipelines
        print("##vso[task.setvariable variable=databricksClusterId;issecret=false]{0}".format(cluster_id))
        return
    else:
        return response.text


if __name__ == '__main__':
    sys.exit(main())
