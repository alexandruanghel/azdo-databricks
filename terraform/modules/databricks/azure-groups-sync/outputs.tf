output "databricks_users" {
  description = "The details of the Databricks users."
  value       = databricks_user.users
}

output "databricks_service_principals" {
  description = "The details of the Databricks service principals."
  value       = databricks_service_principal.sps
}

output "databricks_groups" {
  description = "The details of the Databricks groups."
  value       = databricks_group.groups
}

output "databricks_groups_membership" {
  description = "The Databricks IDs for the groups and their members."
  value       = databricks_group_member.all
}
