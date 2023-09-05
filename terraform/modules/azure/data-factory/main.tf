/**
* Creates an Azure Data Factory with optional Key Vault linked services.
*/
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

locals {
  location = var.azure_location == null ? data.azurerm_resource_group.this.location : var.azure_location

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "azurerm_data_factory" "this" {
  name                   = var.data_factory_name
  location               = local.location
  resource_group_name    = data.azurerm_resource_group.this.name
  public_network_enabled = true
  tags                   = merge(local.tags, var.tags)
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_data_factory_linked_service_key_vault" "key_vaults" {
  count           = length(var.key_vault_ids)
  name            = element(split("/", var.key_vault_ids[count.index]), length(split("/", var.key_vault_ids[count.index]))-1)
  data_factory_id = azurerm_data_factory.this.id
  key_vault_id    = var.key_vault_ids[count.index]
}
