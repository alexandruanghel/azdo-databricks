output "databricks_users" {
  description = "The details of the Databricks users."
  value       = [for user, value in module.databricks_users : value["details"]]
}

output "databricks_service_principals" {
  description = "The details of the Databricks service principals."
  value       = [for user, value in module.databricks_service_principals : value["details"]]
}

output "databricks_groups" {
  description = "The details of the Databricks groups."
  value       = [for user, value in module.databricks_groups : value["details"]]
}

output "databricks_groups_membership" {
  description = "The Databricks IDs for the groups and their members."
  value       = databricks_group_member.all
}
