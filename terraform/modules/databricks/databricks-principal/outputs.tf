output "id" {
  description = "The ID of the principal in the Databricks workspace."
  value       = coalescelist(flatten([databricks_user.user, databricks_service_principal.sp, databricks_group.group]))[0].id
}

output "details" {
  description = "The Databricks details of the principal in the Databricks workspace."
  value       = coalescelist(flatten([databricks_user.user, databricks_service_principal.sp, databricks_group.group]))[0]
}

output "membership" {
  description = "List of groups this principal belongs to."
  value       = data.databricks_group.groups
}
