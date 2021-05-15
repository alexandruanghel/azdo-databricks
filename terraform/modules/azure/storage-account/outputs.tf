output "id" {
  description = "The ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The name of the Storage Account."
  value       = azurerm_storage_account.this.name
}
