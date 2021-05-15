variable "groups" {
  type        = list(string)
  description = "The list of groups to be synced."
}

variable "allow_cluster_create" {
  type        = list(string)
  description = "(Optional) A list of groups that should have cluster create privileges."
  default     = []
}

variable "allow_instance_pool_create" {
  type        = list(string)
  description = "(Optional) A list of groups that should have instance pool create privileges."
  default     = []
}
