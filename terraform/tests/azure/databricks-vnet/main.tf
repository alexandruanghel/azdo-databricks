/**
* Tests for the databricks-vnet module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 1.5.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
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
  numeric = true
  lower   = true
  upper   = false
  special = false
}

# Set the rest of the test variables using the random string
locals {
  resource_group_name                    = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  managed_resource_group_name            = "tftest-rg-managed-${random_string.suffix.result}"
  virtual_network_custom_name            = "tftest-vnet-${random_string.suffix.result}"
  virtual_network_with_nat_defaults_name = "tftest-vnet-nat-default-${random_string.suffix.result}"
  virtual_network_with_nat_custom_name   = "tftest-vnet-nat-custom-${random_string.suffix.result}"
  custom_tags                            = { Purpose = "Terraform-test-${random_string.suffix.result}" }
}

# Create an empty Resource Group to be used by the rest of the resources
data "azurerm_client_config" "current" {}

module "test_resource_group" {
  source              = "../../../modules/azure/resource-group"
  azure_location      = var.azure_location
  resource_group_name = local.resource_group_name
  owners              = [data.azurerm_client_config.current.object_id]
  tags                = local.custom_tags
}

# Marker for test dependencies
resource "null_resource" "test_dependencies" {
  triggers = {
    rg = module.test_resource_group.id
  }
  depends_on = [module.test_resource_group]
}

# Build a VNet with default parameters
module "test_databricks_vnet_defaults" {
  source              = "../../../modules/azure/databricks-vnet"
  resource_group_name = local.resource_group_name
  depends_on          = [null_resource.test_dependencies]
}

# Build a VNet with custom parameters
module "test_databricks_vnet_custom" {
  source                      = "../../../modules/azure/databricks-vnet"
  azure_location              = var.azure_location
  resource_group_name         = local.resource_group_name
  virtual_network_name        = local.virtual_network_custom_name
  network_security_group_name = "tftest-nsg-${random_string.suffix.result}"
  private_subnet_name         = "tftest-private-${random_string.suffix.result}"
  public_subnet_name          = "tftest-public-${random_string.suffix.result}"
  tags                        = local.custom_tags
  depends_on                  = [null_resource.test_dependencies]
}

# Build a VNet with NAT Gateway and default names
module "test_databricks_vnet_with_nat_defaults" {
  source                      = "../../../modules/azure/databricks-vnet"
  resource_group_name         = local.resource_group_name
  virtual_network_name        = local.virtual_network_with_nat_defaults_name
  network_security_group_name = "tftest-nsg-nat1-${random_string.suffix.result}"
  private_subnet_name         = "tftest-private-nat1-${random_string.suffix.result}"
  public_subnet_name          = "tftest-public-nat1-${random_string.suffix.result}"
  use_nat_gateway             = true
  depends_on                  = [null_resource.test_dependencies]
}

# Build a VNet with NAT Gateway and custom parameters
module "test_databricks_vnet_with_nat_custom" {
  source                      = "../../../modules/azure/databricks-vnet"
  azure_location              = var.azure_location
  resource_group_name         = local.resource_group_name
  virtual_network_name        = local.virtual_network_with_nat_custom_name
  network_security_group_name = "tftest-nsg-nat2-${random_string.suffix.result}"
  private_subnet_name         = "tftest-private-nat2-${random_string.suffix.result}"
  public_subnet_name          = "tftest-public-nat2-${random_string.suffix.result}"
  use_nat_gateway             = true
  nat_gateway_name            = "tftest-nat-gateway-${random_string.suffix.result}"
  nat_gateway_public_ip_name  = "tftest-nat-public-ip-${random_string.suffix.result}"
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
      nat_gateway_id            = module.test_databricks_vnet_defaults.nat_gateway_id
      nat_public_ip_id          = module.test_databricks_vnet_defaults.nat_public_ip_id
    }
    test_databricks_vnet_custom = {
      virtual_network_id        = module.test_databricks_vnet_custom.virtual_network_id
      virtual_network_name      = module.test_databricks_vnet_custom.virtual_network_name
      private_subnet_id         = module.test_databricks_vnet_custom.private_subnet_id
      private_subnet_name       = module.test_databricks_vnet_custom.private_subnet_name
      public_subnet_id          = module.test_databricks_vnet_custom.public_subnet_id
      public_subnet_name        = module.test_databricks_vnet_custom.public_subnet_name
      network_security_group_id = module.test_databricks_vnet_custom.network_security_group_id
      nat_gateway_id            = module.test_databricks_vnet_custom.nat_gateway_id
      nat_public_ip_id          = module.test_databricks_vnet_custom.nat_public_ip_id
    }
    test_databricks_vnet_with_nat_defaults = {
      virtual_network_id        = module.test_databricks_vnet_with_nat_defaults.virtual_network_id
      virtual_network_name      = module.test_databricks_vnet_with_nat_defaults.virtual_network_name
      private_subnet_id         = module.test_databricks_vnet_with_nat_defaults.private_subnet_id
      private_subnet_name       = module.test_databricks_vnet_with_nat_defaults.private_subnet_name
      public_subnet_id          = module.test_databricks_vnet_with_nat_defaults.public_subnet_id
      public_subnet_name        = module.test_databricks_vnet_with_nat_defaults.public_subnet_name
      network_security_group_id = module.test_databricks_vnet_with_nat_defaults.network_security_group_id
      nat_gateway_id            = module.test_databricks_vnet_with_nat_defaults.nat_gateway_id
      nat_public_ip_id          = module.test_databricks_vnet_with_nat_defaults.nat_public_ip_id
    }
    test_databricks_vnet_with_nat_custom = {
      virtual_network_id        = module.test_databricks_vnet_with_nat_custom.virtual_network_id
      virtual_network_name      = module.test_databricks_vnet_with_nat_custom.virtual_network_name
      private_subnet_id         = module.test_databricks_vnet_with_nat_custom.private_subnet_id
      private_subnet_name       = module.test_databricks_vnet_with_nat_custom.private_subnet_name
      public_subnet_id          = module.test_databricks_vnet_with_nat_custom.public_subnet_id
      public_subnet_name        = module.test_databricks_vnet_with_nat_custom.public_subnet_name
      network_security_group_id = module.test_databricks_vnet_with_nat_custom.network_security_group_id
      nat_gateway_id            = module.test_databricks_vnet_with_nat_custom.nat_gateway_id
      nat_public_ip_id          = module.test_databricks_vnet_with_nat_custom.nat_public_ip_id
    }
  }
}
