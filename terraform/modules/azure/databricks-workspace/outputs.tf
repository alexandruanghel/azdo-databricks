output "id" {
  description = "The Azure Resource ID of the Databricks workspace."
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_name" {
  description = "The name of the Databricks workspace."
  value       = azurerm_databricks_workspace.this.name
}

output "workspace_id" {
  description = "The unique identifier of the Databricks workspace in Databricks control plane."
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "workspace_url" {
  description = "The workspace URL which is of the format 'adb-{workspace_id}.{random}.azuredatabricks.net'."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "managed_resource_group_name" {
  description = "The name of the Managed Resource Group for managed Databricks resources."
  value       = azurerm_databricks_workspace.this.managed_resource_group_name
}

output "managed_resource_group_id" {
  description = "The Azure Resource ID of the Managed Resource Group."
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}
