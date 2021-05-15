variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which the resources should exist."
}

variable "azure_location" {
  type        = string
  description = "(Optional) Azure location in which the resources should exist. If not set, it will use the location of the Resource Group."
  default     = null
}

variable "data_factory_name" {
  type        = string
  description = "The name of the Azure Data Factory."

  validation {
    condition     = length(var.data_factory_name) >= 3 && length(var.data_factory_name) <= 63
    error_message = "The name of the Azure Data Factory must be between 3 and 63 characters."
  }
}

variable "key_vault_ids" {
  type        = list(string)
  description = "(Optional) A list of Azure Key Vault IDs to be used for creating linked services."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources."
  default     = {}
}
