/**
* Tests for the databricks-workspace module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.59"
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
  workspace_defaults          = var.databricks_workspace_name == null ? "tftest-defaults-${random_string.suffix.result}" : var.databricks_workspace_name
  workspace_vnet_injection    = "tftest-custom-vnet-${random_string.suffix.result}"
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
  triggers = {
    rg = azurerm_resource_group.test.id
  }
  depends_on = [azurerm_resource_group.test]
}

# Build a Databricks workspace with default parameters
module "test_databricks_workspace_defaults" {
  source              = "../../../modules/azure/databricks-workspace"
  resource_group_name = local.resource_group_name
  workspace_name      = local.workspace_defaults
  depends_on          = [null_resource.test_dependencies]
}

# Build a VNet for injection
module "test_databricks_vnet" {
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

# Build a Databricks workspace with VNet injection and custom Managed Resource Group
module "test_databricks_workspace_vnet_injection" {
  source                      = "../../../modules/azure/databricks-workspace"
  azure_location              = var.azure_location
  resource_group_name         = local.resource_group_name
  workspace_name              = local.workspace_vnet_injection
  managed_resource_group_name = local.managed_resource_group_name
  pricing_tier                = "trial"
  virtual_network_id          = module.test_databricks_vnet.virtual_network_id
  private_subnet_name         = module.test_databricks_vnet.private_subnet_name
  public_subnet_name          = module.test_databricks_vnet.public_subnet_name
  tags                        = local.custom_tags
  depends_on                  = [module.test_databricks_vnet]
}

# Terraform output
output "databricks_workspace_tests" {
  value = {
    test_databricks_workspace_defaults = {
      workspace_azure_id = module.test_databricks_workspace_defaults.id
      workspace_name     = module.test_databricks_workspace_defaults.workspace_name
      workspace_id       = module.test_databricks_workspace_defaults.workspace_id
      workspace_url      = module.test_databricks_workspace_defaults.workspace_url
      workspace_managed_resource_group_id   = module.test_databricks_workspace_defaults.managed_resource_group_id
      workspace_managed_resource_group_name = module.test_databricks_workspace_defaults.managed_resource_group_name
    }
    test_databricks_workspace_vnet_injection = {
      workspace_azure_id = module.test_databricks_workspace_vnet_injection.id
      workspace_name     = module.test_databricks_workspace_vnet_injection.workspace_name
      workspace_id       = module.test_databricks_workspace_vnet_injection.workspace_id
      workspace_url      = module.test_databricks_workspace_vnet_injection.workspace_url
      workspace_managed_resource_group_id   = module.test_databricks_workspace_vnet_injection.managed_resource_group_id
      workspace_managed_resource_group_name = module.test_databricks_workspace_vnet_injection.managed_resource_group_name
    }
  }
}
