## Databricks Secrets

# Create the Databricks Secret Scope
resource "databricks_secret_scope" "main" {
  name = var.DATABRICKS_SECRET_SCOPE_NAME
}

# Give READ on the Secret Scope to the Azure Data Factory Managed Identity
resource "databricks_secret_acl" "data_factory_principal" {
  principal  = data.azuread_service_principal.data_factory.application_id
  permission = "READ"
  scope      = databricks_secret_scope.main.name
  depends_on = [databricks_service_principal.data_factory]
}

# Give WRITE on the Secret Scope to the data pipeline Service Principal
resource "databricks_secret_acl" "data_pipeline_principal" {
  principal  = data.azuread_service_principal.data_pipeline.application_id
  permission = "WRITE"
  scope      = databricks_secret_scope.main.name
  depends_on = [databricks_service_principal.data_pipeline]
}

# Get the data pipeline Service Principal Client Secret from the Key Vault
data "azurerm_key_vault_secret" "sp_client_secret" {
  name         = var.SECRET_NAME_CLIENT_SECRET
  key_vault_id = data.azurerm_key_vault.main.id
}

# Add the secret from Key Vault to the Databricks Secret Scope
# This needs to be done until Key Vault backed Secret Scopes are supported with Service Principals
resource "databricks_secret" "sp_client_secret" {
  key          = var.SECRET_NAME_CLIENT_SECRET
  string_value = data.azurerm_key_vault_secret.sp_client_secret.value
  scope        = databricks_secret_scope.main.id
}

# Terraform output
output "databricks_secret_scopes" {
  value = {
    main = databricks_secret_scope.main
  }
}

output "data_pipeline_secrets" {
  value = {
    secret_scope_name         = databricks_secret_scope.main.name
    key_vault_name            = data.azurerm_key_vault.main.name
    secret_name_client_secret = databricks_secret.sp_client_secret.key
  }
}
