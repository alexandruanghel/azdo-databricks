output "id" {
  description = "The ID of the Azure Key Vault."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "The name of the Azure Key Vault."
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "The URI of the Azure Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "policy" {
  description = "The Azure Key Vault policy ID."
  value       = azurerm_key_vault_access_policy.creator.id
}
