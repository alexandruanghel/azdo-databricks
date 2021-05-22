### Databricks Instance Pools and Clusters

# Deploy the Jobs Instance Pool
resource "databricks_instance_pool" "jobs" {
  instance_pool_name                    = var.DATABRICKS_JOBS_POOL_NAME
  min_idle_instances                    = 0
  node_type_id                          = var.DATABRICKS_JOBS_POOL_NODE_TYPE
  idle_instance_autotermination_minutes = var.DATABRICKS_JOBS_POOL_AUTOTERMINATION
  preloaded_spark_versions              = [var.DATABRICKS_SPARK_VERSION]

  azure_attributes {
    availability = "ON_DEMAND_AZURE"
  }

  custom_tags = {
    "InstancePoolManagedBy" = "Terraform"
  }
}

# Give CAN_ATTACH_TO on the Jobs Instance Pool to the Data Factory Managed Identity and the data pipeline Service Principal
resource "databricks_permissions" "jobs_pool" {
  instance_pool_id = databricks_instance_pool.jobs.id

  access_control {
    service_principal_name = data.azuread_service_principal.data_factory.application_id
    permission_level       = "CAN_ATTACH_TO"
  }

  access_control {
    service_principal_name = data.azuread_service_principal.data_pipeline.application_id
    permission_level       = "CAN_ATTACH_TO"
  }

  depends_on = [module.data_factory_databricks_principal, module.data_pipeline_databricks_principal]
}

# Deploy the Shared Instance Pool
resource "databricks_instance_pool" "shared" {
  instance_pool_name                    = var.DATABRICKS_SHARED_POOL_NAME
  min_idle_instances                    = 0
  node_type_id                          = var.DATABRICKS_SHARED_POOL_NODE_TYPE
  idle_instance_autotermination_minutes = var.DATABRICKS_SHARED_POOL_AUTOTERMINATION
  preloaded_spark_versions              = [var.DATABRICKS_SPARK_VERSION]

  azure_attributes {
    availability       = "SPOT_AZURE"
    spot_bid_max_price = -1
  }

  custom_tags = {
    "InstancePoolManagedBy" = "Terraform"
  }
}

# Give CAN_ATTACH_TO on the Shared Instance Pool to the Project group
resource "databricks_permissions" "shared_pool" {
  instance_pool_id = databricks_instance_pool.shared.id

  access_control {
    group_name       = var.PROJECT_GROUP_NAME
    permission_level = "CAN_ATTACH_TO"
  }

  depends_on = [module.project_group_sync]
}

# Deploy the Shared Autoscaling Cluster
resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = var.DATABRICKS_SHARED_CLUSTER_NAME
  spark_version           = var.DATABRICKS_SPARK_VERSION
  instance_pool_id        = databricks_instance_pool.shared.id
  autotermination_minutes = var.DATABRICKS_SHARED_CLUSTER_AUTOTERMINATION

  cluster_log_conf {
    dbfs {
      destination = var.DATABRICKS_CLUSTER_LOG_PATH
    }
  }

  autoscale {
    min_workers = var.DATABRICKS_SHARED_CLUSTER_MIN_WORKERS
    max_workers = var.DATABRICKS_SHARED_CLUSTER_MAX_WORKERS
  }

  azure_attributes {
    availability = "SPOT_AZURE"
  }

  spark_conf = {
    "spark.databricks.cluster.profile": "serverless",
    "spark.databricks.repl.allowedLanguages": "python,sql",
    "spark.databricks.passthrough.enabled": "true",
    "spark.databricks.pyspark.enableProcessIsolation": "true"
  }

  custom_tags = {
    "ResourceClass"    = "Serverless"
    "ClusterManagedBy" = "Terraform"
  }
}

# Give CAN_ATTACH_TO on the Shared Autoscaling Cluster to all users
# Give CAN_RESTART on the Shared Autoscaling Cluster to the Project group
resource "databricks_permissions" "shared_cluster" {
  cluster_id = databricks_cluster.shared_autoscaling.id

  access_control {
    group_name       = "users"
    permission_level = "CAN_ATTACH_TO"
  }

  access_control {
    group_name       = var.PROJECT_GROUP_NAME
    permission_level = "CAN_RESTART"
  }

  depends_on = [module.project_group_sync]
}

# Terraform output
output "databricks_instance_pools" {
  value = {
    jobs_pool   = databricks_instance_pool.jobs
    shared_pool = databricks_instance_pool.shared
  }
}

output "databricks_clusters" {
  value = {
    shared_autoscaling = databricks_cluster.shared_autoscaling
  }
}
