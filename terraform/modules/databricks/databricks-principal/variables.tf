variable "principal_identifier" {
  type        = string
  description = "The identifier of the principal (user name, service principal id or group name)."
}

variable "principal_type" {
  type        = string
  description = "The type of the principal. Can be user, group or service_principal."

  validation {
    condition     = contains(["user", "group", "service_principal"], var.principal_type)
    error_message = "The principal type must be 'user', 'group' or 'service_principal'."
  }
}

variable "display_name" {
  type        = string
  description = "(Optional) The display name of the principal. Default is an empty string."
  default     = ""
}

variable "allow_cluster_create" {
  type        = bool
  description = "(Optional) Allows the principal to have cluster create privileges. Default is false."
  default     = false
}

variable "allow_instance_pool_create" {
  type        = bool
  description = "(Optional) Allows the principal to have instance pool create privileges. Default is false."
  default     = false
}

variable "databricks_sql_access" {
  type        = bool
  description = "(Optional) Allows the principal to have access to Databricks SQL feature. Default is false."
  default     = false
}

variable "groups" {
  type        = list(string)
  description = "(Optional) A list of groups this principal should be member of."
  default     = []
}
