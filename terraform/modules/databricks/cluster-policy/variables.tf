variable "policy_name" {
  type        = string
  description = "Cluster policy name."
}

variable "CAN_USE" {
  type = list(object({
    principal = string
    type      = string
  })
  )
  description = "(Optional) Objects of principals that should have CAN_USE permission on the policy."
  default     = []
}

variable "default_spark_version_regex" {
  type        = string
  description = "(Optional) The default policy Spark version regex. Default is `.*-scala2.12`"
  default     = ".*-scala2.12"
}

variable "default_autotermination_minutes" {
  type        = number
  description = "(Optional) The default policy cluster autotermination in minutes. Default is 120 minutes."
  default     = 120
}

variable "default_cluster_log_path" {
  type        = string
  description = "(Optional) The default policy location to deliver Spark driver, worker, and event logs. Default is `dbfs:/cluster-logs`."
  default     = "dbfs:/cluster-logs"
}

variable "policy_overrides_file" {
  type        = string
  description = "(Optional) The path to a json file containing any cluster policy overrides."
  default     = null
}

variable "policy_overrides_object" {
  description = "(Optional) Cluster policy overrides defined as object."
  default     = {}
}
