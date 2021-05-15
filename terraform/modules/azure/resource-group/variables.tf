variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group."
}

variable "azure_location" {
  type        = string
  description = "Azure location for the Resource Group."
}

variable "owners" {
  type        = list(string)
  description = "(Optional) A list of Object IDs that should have the Owner role over the Resource Group."
  default     = []
}

variable "contributors" {
  type        = list(string)
  description = "(Optional) A list of Object IDs that should have the Contributor role over the Resource Group."
  default     = []
}

variable "readers" {
  type        = list(string)
  description = "(Optional) A list of Object IDs that should have the Reader role over the Resource Group."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the Resource Group."
  default     = {}
}
