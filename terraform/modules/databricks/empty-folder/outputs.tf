output "id" {
  description = "The path of the folder in the Databricks workspace."
  value       = data.databricks_notebook_paths.folder.id
}

output "details" {
  description = "Details about the folder."
  value       = data.databricks_notebook_paths.folder
}

output "permissions" {
  description = "List with the folder permissions."
  value       = length(databricks_permissions.folder) > 0 ? databricks_permissions.folder[0] : null
}
