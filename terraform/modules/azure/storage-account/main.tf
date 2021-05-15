/**
* Creates an Azure Storage Account with optional Key Vault linked services
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

resource "azurerm_storage_account" "this" {
  name                      = var.storage_account_name
  location                  = local.location
  resource_group_name       = data.azurerm_resource_group.this.name
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = var.account_replication_type
  access_tier               = "Hot"
  is_hns_enabled            = var.hierarchical_namespace
  enable_https_traffic_only = true
  tags                      = merge(local.tags, var.tags)
}

resource "azurerm_storage_container" "default" {
  count                 = var.hierarchical_namespace == false ? length(var.storage_containers) : 0
  name                  = var.storage_containers[count.index]
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
  depends_on            = [azurerm_storage_account.this]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "default" {
  count              = var.hierarchical_namespace == true ? length(var.storage_containers) : 0
  name               = var.storage_containers[count.index]
  storage_account_id = azurerm_storage_account.this.id
  depends_on         = [azurerm_storage_account.this]
}

resource "azurerm_storage_account_network_rules" "default" {
  resource_group_name        = data.azurerm_resource_group.this.name
  storage_account_name       = azurerm_storage_account.this.name
  default_action             = var.network_default_action
  ip_rules                   = var.allowed_ips
  virtual_network_subnet_ids = var.allowed_subnet_ids
  bypass                     = ["Logging", "Metrics", "AzureServices"]
  depends_on                 = [azurerm_storage_container.default, azurerm_storage_data_lake_gen2_filesystem.default]
}
