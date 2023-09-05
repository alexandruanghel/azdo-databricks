variable "DATA_SERVICE_PRINCIPAL_CLIENT_ID" {
  type        = string
  description = "The Service Principal Client ID used by the data pipeline. This must already exist in the Azure AD Tenant."
}

variable "PROJECT_GROUP_NAME" {
  type        = string
  description = "The name of the Project User Group. This must already exist in the Azure AD Tenant."
}

variable "RESOURCE_GROUP_NAME" {
  type        = string
  description = "The name of the Resource Group in which the resources should be built. This must already exist."
}

variable "KEY_VAULT_NAME" {
  type        = string
  description = "The name of the Azure Key Vault. This must already exist in the Azure AD Tenant."
}

variable "SECRET_NAME_CLIENT_SECRET" {
  type        = string
  description = "The name of the secret that holds the data pipeline Service Principal Client Secret."
}

variable "STORAGE_ACCOUNT_NAME" {
  type        = string
  description = "The name of the Storage Account. This must already exist."
}

variable "PIPELINE_CONTAINER_NAME" {
  type        = string
  description = "ADLS Gen 2 Filesystem Container for the Pipeline Data. This must already exist."
}

variable "PROJECT_CONTAINER_NAME" {
  type        = string
  description = "ADLS Gen 2 Filesystem Container for the Project Data. It will be mounted to the Databricks workspace. This must already exist."
}

variable "PROJECT_MOUNT_POINT" {
  type        = string
  description = "(Optional) DBFS mount location of the Project container. If not set, it will use /mnt/<STORAGE_ACCOUNT>-<CONTAINER_NAME>."
  default     = null
}

variable "DATA_FACTORY_NAME" {
  type        = string
  description = "The name of the Azure Data Factory. This must already exist."
}

variable "DATABRICKS_WORKSPACE_NAME" {
  type        = string
  description = "The name of the Databricks workspace. This must already exist."
}

variable "DATABRICKS_SECRET_SCOPE_NAME" {
  type        = string
  description = "The name of the Databricks Secret Scope."
}

variable "DATABRICKS_JOBS_POOL_NAME" {
  type        = string
  description = "The name of the Databricks Jobs Instance Pool."
}

variable "DATABRICKS_JOBS_POOL_NODE_TYPE" {
  type        = string
  description = "The Azure node type in the Jobs Pool."
}

variable "DATABRICKS_JOBS_POOL_AUTOTERMINATION" {
  type        = number
  description = "(Optional) The number of minutes that idle instances are maintained by the Jobs Pool before being terminated. Default is 60 minutes."
  default     = 60 # minutes
}

variable "DATABRICKS_SHARED_POOL_NAME" {
  type        = string
  description = "The name of the Databricks Shared Instance Pool."
}

variable "DATABRICKS_SHARED_POOL_NODE_TYPE" {
  type        = string
  description = "The Azure node type in the Shared Pool."
}

variable "DATABRICKS_SHARED_POOL_AUTOTERMINATION" {
  type        = number
  description = "(Optional) The number of minutes that idle instances are maintained by the Shared Pool before being terminated. Default is 120 minutes."
  default     = 120 # minutes
}
variable "DATABRICKS_SHARED_CLUSTER_NAME" {
  type        = string
  description = "The name of the Databricks Shared Cluster."
}

variable "DATABRICKS_SHARED_CLUSTER_AUTOTERMINATION" {
  type        = number
  description = "(Optional) The number of minutes that idle instances are maintained by the Shared Pool before being terminated. Default is 120 minutes."
  default     = 120 # minutes
}

variable "DATABRICKS_SHARED_CLUSTER_MIN_WORKERS" {
  type        = number
  description = "(Optional) The number of worker nodes in the Databricks Shared Cluster. Default is 1."
  default     = 1
}

variable "DATABRICKS_SHARED_CLUSTER_MAX_WORKERS" {
  type        = number
  description = "(Optional) The maximum number of worker nodes in the Databricks Shared Cluster. Default is 10."
  default     = 10
}

variable "DATABRICKS_SPARK_VERSION" {
  type        = string
  description = "(Optional) The Databricks Spark Version used by the Instance Pools and the Shared Cluster. Default is `13.3.x-scala2.12`."
  default     = "13.3.x-scala2.12"
}

variable "DATABRICKS_CLUSTER_POLICY_LOCATION" {
  type        = string
  description = "Location of the Cluster Policy json file."
}

variable "DATABRICKS_CLUSTER_LOG_PATH" {
  type        = string
  description = "(Optional) Location to deliver Spark driver, worker, and event logs. Default is `dbfs:/cluster-logs`."
  default     = "dbfs:/cluster-logs"
}

variable "NOTEBOOKS_SHARED_SOURCE_LOCATION" {
  type        = string
  description = "Location of generic notebooks to be deployed in a shared Databricks workspace folder."
}

variable "NOTEBOOKS_SHARED_WORKSPACE_FOLDER" {
  type        = string
  description = "Folder path in the Databricks workspace where the shared notebooks will be deployed."
}

variable "NOTEBOOKS_PROJECT_WORKSPACE_FOLDER" {
  type        = string
  description = "Databricks workspace folder for the Project notebooks."
}

variable "NOTEBOOKS_PIPELINE_WORKSPACE_FOLDER" {
  type        = string
  description = "Databricks workspace folder for the data pipeline notebooks."
}

