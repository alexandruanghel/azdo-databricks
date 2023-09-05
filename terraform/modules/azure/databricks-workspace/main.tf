/**
* Creates an Azure Databricks workspace with optional VNet injection (https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-inject).
*/
data "azurerm_resource_group" "databricks" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "databricks_vnet" {
  count               = var.virtual_network_name == null ? 0 : 1
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.databricks.name
}

data "azurerm_subnet" "databricks_public_subnet" {
  count                = var.virtual_network_name == null ? 0 : 1
  name                 = var.public_subnet_name
  virtual_network_name = data.azurerm_virtual_network.databricks_vnet[0].name
  resource_group_name  = data.azurerm_resource_group.databricks.name
}

data "azurerm_subnet" "databricks_private_subnet" {
  count                = var.virtual_network_name == null ? 0 : 1
  name                 = var.private_subnet_name
  virtual_network_name = data.azurerm_virtual_network.databricks_vnet[0].name
  resource_group_name  = data.azurerm_resource_group.databricks.name
}

resource "random_string" "rg_suffix" {
  length  = 10
  numeric = true
  lower   = true
  upper   = false
  special = false

  keepers = {
    workspace_name = var.workspace_name
  }
}

locals {
  location                    = var.azure_location == null ? data.azurerm_resource_group.databricks.location : var.azure_location
  managed_resource_group_name = var.managed_resource_group_name == null ? "databricks-rg-${var.workspace_name}-${random_string.rg_suffix.result}" : var.managed_resource_group_name

  tags = {
    WorkspaceManagedBy = "Terraform"
  }
}

resource "azurerm_databricks_workspace" "this" {
  name                        = var.workspace_name
  location                    = local.location
  resource_group_name         = data.azurerm_resource_group.databricks.name
  sku                         = var.pricing_tier
  managed_resource_group_name = local.managed_resource_group_name
  tags                        = merge(local.tags, var.tags)

  dynamic "custom_parameters" {
    for_each = var.virtual_network_name == null ? [] : [1]
    content {
      no_public_ip        = var.disable_public_ip
      virtual_network_id  = data.azurerm_virtual_network.databricks_vnet[0].id
      private_subnet_name = var.private_subnet_name
      public_subnet_name  = var.public_subnet_name

      private_subnet_network_security_group_association_id = data.azurerm_subnet.databricks_private_subnet[0].id
      public_subnet_network_security_group_association_id  = data.azurerm_subnet.databricks_public_subnet[0].id
    }
  }
}

# Wait for 5 minutes to allow permissions and network rules to propagate to the Managed Resource Group
resource "time_sleep" "wait_5_min" {
  create_duration = "300s"
  depends_on      = [azurerm_databricks_workspace.this]
}
