/**
* Tests for the databricks-vnet module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.58"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Minimum of variables required for the test
variable "azure_location" { default = "westeurope" }
variable "resource_group_name" { default = null }
variable "databricks_workspace_name" { default = null }

# Create a random string for test uniqueness
resource "random_string" "suffix" {
  length  = 10
  number  = true
  lower   = true
  upper   = false
  special = false
}

# Set the rest of the test variables using the random string
locals {
  resource_group_name         = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  managed_resource_group_name = "tftest-managed-rg-${random_string.suffix.result}"
  virtual_network_name        = "tftest-vnet-${random_string.suffix.result}"
  network_security_group_name = "tftest-nsg-${random_string.suffix.result}"
  private_subnet_name         = "tftest-private-${random_string.suffix.result}"
  public_subnet_name          = "tftest-public-${random_string.suffix.result}"
  custom_tags                 = { Purpose = "Terraform-test-${random_string.suffix.result}" }
}

# Create an empty Resource Group to be used by the rest of the resources
resource "azurerm_resource_group" "test" {
  name     = local.resource_group_name
  location = var.azure_location
  tags     = local.custom_tags
}

# Marker for test dependencies
resource "null_resource" "test_dependencies" {
  triggers   = {
    rg = azurerm_resource_group.test.id
  }
  depends_on = [azurerm_resource_group.test]
}

# Build a VNet with default parameters
module "test_databricks_vnet_defaults" {
  source               = "../../../modules/azure/databricks-vnet"
  resource_group_name  = local.resource_group_name
  depends_on           = [null_resource.test_dependencies]
}

# Build a VNet with custom parameters
module "test_databricks_vnet_custom" {
  source                      = "../../../modules/azure/databricks-vnet"
  azure_location              = var.azure_location
  resource_group_name         = local.resource_group_name
  virtual_network_name        = local.virtual_network_name
  network_security_group_name = local.network_security_group_name
  private_subnet_name         = local.private_subnet_name
  public_subnet_name          = local.public_subnet_name
  tags                        = local.custom_tags
  depends_on                  = [null_resource.test_dependencies]
}

# Terraform output
output "databricks_vnet_tests" {
  value = {
    test_databricks_vnet_defaults = {
      virtual_network_id        = module.test_databricks_vnet_defaults.virtual_network_id
      virtual_network_name      = module.test_databricks_vnet_defaults.virtual_network_name
      private_subnet_id         = module.test_databricks_vnet_defaults.private_subnet_id
      private_subnet_name       = module.test_databricks_vnet_defaults.private_subnet_name
      public_subnet_id          = module.test_databricks_vnet_defaults.public_subnet_id
      public_subnet_name        = module.test_databricks_vnet_defaults.public_subnet_name
      network_security_group_id = module.test_databricks_vnet_defaults.network_security_group_id
    }
    test_databricks_vnet_custom = {
      virtual_network_id        = module.test_databricks_vnet_custom.virtual_network_id
      virtual_network_name      = module.test_databricks_vnet_custom.virtual_network_name
      private_subnet_id         = module.test_databricks_vnet_custom.private_subnet_id
      private_subnet_name       = module.test_databricks_vnet_custom.private_subnet_name
      public_subnet_id          = module.test_databricks_vnet_custom.public_subnet_id
      public_subnet_name        = module.test_databricks_vnet_custom.public_subnet_name
      network_security_group_id = module.test_databricks_vnet_custom.network_security_group_id
    }
  }
}
