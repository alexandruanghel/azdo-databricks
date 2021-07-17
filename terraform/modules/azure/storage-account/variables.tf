variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which the resources should exist."
}

variable "azure_location" {
  type        = string
  description = "(Optional) Azure location in which the resources should exist. If not set, it will use the location of the Resource Group."
  default     = null
}

variable "storage_account_name" {
  type        = string
  description = "The name of the Storage Account."

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "The name of the Storage Account must be between 3 and 24 characters."
  }
}

variable "hierarchical_namespace" {
  type        = bool
  description = "(Optional) Set to true for an Azure Data Lake Gen 2 Storage Account. Default is false."
  default     = false
}

variable "storage_containers" {
  type        = list(string)
  description = "(Optional) A list of containers to be created within the Storage Account. By default it will create a container called default."
  default     = ["default"]
}

variable "account_replication_type" {
  type        = string
  description = "(Optional) The type of replication to use for the Storage Account. Default is LRS."
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS."
  }
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "(Optional) The virtual network subnet IDs allowed to connect to the Storage Account."
  default     = []
}

variable "allowed_ips" {
  type        = list(string)
  description = "(Optional) The IPs allowed to connect to the Storage Account."
  default     = []
}

variable "network_default_action" {
  type        = string
  description = "(Optional) Specifies the default action of allow or deny when no other rules match. Default is Allow."
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "Valid options are Deny or Allow."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources."
  default     = {}
}
