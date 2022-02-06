variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which the resources should exist."
}

variable "azure_location" {
  type        = string
  description = "(Optional) Azure location in which the resources should exist. If not set, it will use the location of the Resource Group."
  default     = null
}

variable "workspace_name" {
  type        = string
  description = "The name of the Azure Databricks workspace resource."

  validation {
    condition     = length(var.workspace_name) >= 3 && length(var.workspace_name) <= 30
    error_message = "The name of the Databricks workspace must be between 3 and 30 characters."
  }
}

variable "managed_resource_group_name" {
  type        = string
  description = "(Optional) The name of the Resource Group where Azure should place the managed Databricks resources. This should not already exist."
  default     = null
}

variable "pricing_tier" {
  type        = string
  description = "(Optional) The pricing tier to use for the Databricks workspace. Possible values are standard, premium, or trial. Default is premium."
  default     = "premium"

  validation {
    condition     = contains(["premium", "standard", "trial"], var.pricing_tier)
    error_message = "The Azure Databricks Pricing Tier must be set to premium, standard or trial."
  }
}

variable "virtual_network_name" {
  type        = string
  description = "(Optional) The Azure Resource ID of the Virtual Network for VNet injection. If not set, a new Virtual Network will be created in the Managed Resource Group."
  default     = null
}

variable "private_subnet_name" {
  type        = string
  description = "(Optional) The name of the Private Subnet within the Virtual Network. Default is private-subnet."
  default     = "private-subnet"
}

variable "public_subnet_name" {
  type        = string
  description = "(Optional) The name of the Public Subnet within the Virtual Network. Default is public-subnet."
  default     = "public-subnet"
}

variable "disable_public_ip" {
  type        = bool
  description = "(Optional) Set to true to deploy the workspace with Secure Cluster Connectivity (No Public IP) enabled. Default is false."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources."
  default     = {}
}
