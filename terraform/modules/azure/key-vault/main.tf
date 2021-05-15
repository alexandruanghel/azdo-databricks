/**
* Creates an Azure Key Vault.
* Gives "Key, Secret, & Certificate Management" policies to the creator.
*/
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

locals {
  location = var.azure_location == null ? data.azurerm_resource_group.this.location : var.azure_location

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
  location                   = local.location
  resource_group_name        = data.azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = false
  sku_name                   = var.sku_name
  tags                       = merge(local.tags, var.tags)
}

data "azurerm_key_vault_access_policy" "all" {
  name = "Key, Secret, & Certificate Management"
}

resource "azurerm_key_vault_access_policy" "creator" {
  key_vault_id       = azurerm_key_vault.this.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  certificate_permissions = concat(data.azurerm_key_vault_access_policy.all.certificate_permissions, ["purge"])
  key_permissions         = concat(data.azurerm_key_vault_access_policy.all.key_permissions, ["purge"])
  secret_permissions      = concat(data.azurerm_key_vault_access_policy.all.secret_permissions, ["purge"])
}
