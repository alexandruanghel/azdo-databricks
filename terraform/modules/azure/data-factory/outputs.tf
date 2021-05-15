output "id" {
  description = "The ID of the Azure Data Factory."
  value       = azurerm_data_factory.this.id
}

output "name" {
  description = "The name of the Azure Data Factory."
  value       = azurerm_data_factory.this.name
}

output "principal_id" {
  description = "The ID of the Azure Data Factory Managed Identity in Azure Active Directory."
  value       = azurerm_data_factory.this.identity[0].principal_id
}

output "key_vault_linked_services" {
  description = "Details of the Azure Data Factory linked Key Vault services."
  value       = azurerm_data_factory_linked_service_key_vault.key_vaults[*]
}
