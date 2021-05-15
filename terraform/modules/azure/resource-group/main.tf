/**
* Creates an Azure Resource Group with optional IAM roles
*/
data "azurerm_client_config" "current" {}

locals {
  tags = {
    ManagedBy = "Terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.azure_location
  tags     = merge(local.tags, var.tags)
}

resource "azurerm_role_assignment" "owners" {
  count                = length(var.owners)
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Owner"
  principal_id         = var.owners[count.index]
}

resource "azurerm_role_assignment" "contributors" {
  count                = length(var.contributors)
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = var.contributors[count.index]
}

resource "azurerm_role_assignment" "readers" {
  count                = length(var.readers)
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = var.readers[count.index]
}
