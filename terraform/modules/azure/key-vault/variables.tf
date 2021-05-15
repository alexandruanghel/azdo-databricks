variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which the resources should exist."
}

variable "azure_location" {
  type        = string
  description = "(Optional) Azure location in which the resources should exist. If not set, it will use the location of the Resource Group."
  default     = null
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Azure Key Vault."

  validation {
    condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24
    error_message = "The name of the Key Vault must be between 3 and 24 characters."
  }
}

variable "sku_name" {
  type        = string
  description = "(Optional) The name of the SKU used for this Key Vault. Possible values are standard and premium. Default is standard."
  default     = "standard"

  validation {
    condition     = contains(["premium", "standard"], var.sku_name)
    error_message = "Possible values are standard and premium."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  description = "(Optional) The number of days that items should be retained for once soft-deleted. Default is 7 days."
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "This value can be between 7 and 90 days."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources."
  default     = {}
}
