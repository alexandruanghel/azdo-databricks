output "object_id" {
  description = "The AD Object ID of the Service Principal."
  value       = azuread_service_principal.sp.object_id
}

output "application_id" {
  description = "The Application ID (Client ID) of the Service Principal."
  value       = azuread_service_principal.sp.application_id
}

output "secret" {
  description = "The Password / Secret (Client Secret) of the Service Principal."
  value       = azuread_application_password.sp.value
  sensitive   = true
}
