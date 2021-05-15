output "id" {
  description = "The ID of the cluster policy in the Databricks workspace."
  value       = databricks_cluster_policy.this.id
}

output "details" {
  description = "Details about the cluster policy."
  value       = databricks_cluster_policy.this
}

output "permissions" {
  description = "List with the cluster policy permissions."
  value       = length(databricks_permissions.policy) > 0 ? databricks_permissions.policy[0] : null
}
