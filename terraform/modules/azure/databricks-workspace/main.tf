/**
* Creates an Azure Databricks workspace with optional VNet injection (https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-inject).
*/
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "random_string" "rg_suffix" {
  length  = 10
  number  = true
  lower   = true
  upper   = false
  special = false

  keepers = {
    workspace_name = var.workspace_name
  }
}

locals {
  location                    = var.azure_location == null ? data.azurerm_resource_group.this.location : var.azure_location
  managed_resource_group_name = var.managed_resource_group_name == null ? "databricks-rg-${var.workspace_name}-${random_string.rg_suffix.result}" : var.managed_resource_group_name

  tags = {
    WorkspaceManagedBy = "Terraform"
  }
}

resource "azurerm_databricks_workspace" "this" {
  name                        = var.workspace_name
  location                    = local.location
  resource_group_name         = data.azurerm_resource_group.this.name
  sku                         = var.pricing_tier
  managed_resource_group_name = local.managed_resource_group_name
  tags                        = merge(local.tags, var.tags)

  dynamic "custom_parameters" {
    for_each = var.virtual_network_id == null ? [] : [1]
    content {
      no_public_ip        = var.disable_public_ip
      virtual_network_id  = var.virtual_network_id
      private_subnet_name = var.private_subnet_name
      public_subnet_name  = var.public_subnet_name
    }
  }
}

# Wait for 120s to allow permissions to propagate to the Managed Resource Group
resource "time_sleep" "wait_120_seconds" {
  create_duration = "120s"
  depends_on = [azurerm_databricks_workspace.this]
}
