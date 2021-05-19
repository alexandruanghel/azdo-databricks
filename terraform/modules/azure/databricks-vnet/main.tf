/**
* Creates an Azure Virtual Network for Databricks VNet injection (https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-inject).
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

resource "azurerm_virtual_network" "core" {
  name                = var.virtual_network_name
  location            = local.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = [var.virtual_network_cidr]
  tags                = merge(local.tags, var.tags)
}

resource "azurerm_network_security_group" "databricks" {
  name                = var.network_security_group_name
  location            = local.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = merge(local.tags, var.tags)
}

resource "azurerm_subnet" "databricks_private_subnet" {
  name                 = var.private_subnet_name
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [var.private_subnet_cidr]

  delegation {
    name = "databricks-del-private"

    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "databricks_private_nsg" {
  subnet_id                 = azurerm_subnet.databricks_private_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_subnet" "databricks_public_subnet" {
  name                 = var.public_subnet_name
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [var.public_subnet_cidr]
  service_endpoints    = var.service_endpoints

  delegation {
    name = "databricks-del-public"

    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "databricks_public_nsg" {
  subnet_id                 = azurerm_subnet.databricks_public_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_public_ip" "databricks" {
  count                   = var.use_nat_gateway == true ? 1 : 0
  name                    = var.nat_gateway_public_ip_name
  location                = local.location
  resource_group_name     = data.azurerm_resource_group.this.name
  allocation_method       = "Static"
  sku                     = "Standard"
  ip_version              = "IPv4"
  idle_timeout_in_minutes = 4
}

resource "azurerm_nat_gateway" "databricks" {
  count                   = var.use_nat_gateway == true ? 1 : 0
  name                    = var.nat_gateway_name
  location                = local.location
  resource_group_name     = data.azurerm_resource_group.this.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}

resource "azurerm_nat_gateway_public_ip_association" "databricks" {
  count                = var.use_nat_gateway == true ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.databricks[0].id
  public_ip_address_id = azurerm_public_ip.databricks[0].id
}

resource "azurerm_subnet_nat_gateway_association" "databricks_private_subnet" {
  count          = var.use_nat_gateway == true ? 1 : 0
  subnet_id      = azurerm_subnet.databricks_private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.databricks[0].id
}

resource "azurerm_subnet_nat_gateway_association" "databricks_public_subnet" {
  count          = var.use_nat_gateway == true ? 1 : 0
  subnet_id      = azurerm_subnet.databricks_public_subnet.id
  nat_gateway_id = azurerm_nat_gateway.databricks[0].id
}
