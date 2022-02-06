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

variable "STORAGE_ACCOUNT_NAME" {
  type        = string
  description = "The name of the Storage Account."
}

variable "PIPELINE_CONTAINER_NAME" {
  type        = string
  description = "ADLS Gen 2 Filesystem Container for the Pipeline Data."
}

variable "PROJECT_CONTAINER_NAME" {
  type        = string
  description = "ADLS Gen 2 Filesystem Container for the Project Data. It will be mounted to the Databricks workspace."
}

variable "DATA_FACTORY_NAME" {
  type        = string
  description = "The name of the Azure Data Factory."
}

variable "DATABRICKS_WORKSPACE_NAME" {
  type        = string
  description = "The name of the Azure Databricks workspace."
}

variable "DATABRICKS_PRICING_TIER" {
  type        = string
  description = "(Optional) The pricing tier to use for the Databricks workspace. Possible values are standard, premium, or trial. Default is premium."
  default     = "premium"
}

variable "DATABRICKS_VNET_NAME" {
  type        = string
  description = "(Optional) The name of the Virtual Network where the Databricks clusters should be created. Default is workers-vnet."
  default     = "workers-vnet"
}

variable "DATABRICKS_VNET_CIDR" {
  type        = string
  description = "(Optional) CIDR range for the Virtual Network (must be at least /24). Default is 10.179.0.0/16"
  default     = "10.179.0.0/16"
}

variable "DATABRICKS_PRIVATE_SUBNET_NAME" {
  type        = string
  description = "(Optional) The name of the Private Subnet within the Virtual Network. Default is private-subnet."
  default     = "private-subnet"
}

variable "DATABRICKS_PRIVATE_SUBNET_CIDR" {
  type        = string
  description = "(Optional) CIDR range for the Private Subnet (must be at least /26). Default is 10.179.0.0/18."
  default     = "10.179.0.0/18"
}

variable "DATABRICKS_PUBLIC_SUBNET_NAME" {
  type        = string
  description = "(Optional) The name of the Public Subnet within the Virtual Network. Default is public-subnet."
  default     = "public-subnet"
}

variable "DATABRICKS_PUBLIC_SUBNET_CIDR" {
  type        = string
  description = "(Optional) CIDR range for the Public Subnet (must be at least /26). Default is 10.179.64.0/18."
  default     = "10.179.64.0/18"
}

variable "DATABRICKS_NSG_NAME" {
  type        = string
  description = "(Optional) The name of the Network Security Group attached to the Databricks subnets. Default is databricks-nsg."
  default     = "databricks-nsg"
}

variable "DATABRICKS_DISABLE_PUBLIC_IP" {
  type        = bool
  description = "(Optional) Set to true to deploy the workspace with Secure Cluster Connectivity (No Public IP) enabled. Default is false."
  default     = false
}

variable "deployment_tags" {
  type        = map(string)
  description = "A mapping of tags to assign to all resources."
  default     = {
    DeploymentName = "azure-infrastructure"
  }
}
