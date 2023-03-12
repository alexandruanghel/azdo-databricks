/**
* Tests for the data-factory module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 1.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# Minimum of variables required for the test
variable "azure_location" { default = "westeurope" }
variable "resource_group_name" { default = null }

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
  resource_group_name         = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  data_factory_defaults       = "tftest-defaults-${random_string.suffix.result}"
  data_factory_with_key_vault = "tftest-with-akv-${random_string.suffix.result}"
  key_vault_name              = "tftest-akv-${random_string.suffix.result}"
  custom_tags                 = { Purpose = "Terraform-test-${random_string.suffix.result}" }
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

# Build a Key Vault for the Azure Data Factory linked service
module "key_vault" {
  source              = "../../../modules/azure/key-vault"
  resource_group_name = module.test_resource_group.name
  azure_location      = var.azure_location
  key_vault_name      = local.key_vault_name
}

# Marker for test dependencies
resource "null_resource" "test_dependencies" {
  triggers   = {
    rg = join(",", [module.test_resource_group.id, module.key_vault.id])
  }
  depends_on = [module.test_resource_group, module.key_vault.id]
}

# Build an Azure Data Factory with default parameters
module "test_data_factory_defaults" {
  source              = "../../../modules/azure/data-factory"
  resource_group_name = local.resource_group_name
  data_factory_name   = local.data_factory_defaults
  depends_on          = [null_resource.test_dependencies]
}

# Build an Azure Data Factory with a Key Vault linked service
module "test_data_factory_with_key_vault" {
  source              = "../../../modules/azure/data-factory"
  azure_location      = var.azure_location
  resource_group_name = local.resource_group_name
  data_factory_name   = local.data_factory_with_key_vault
  key_vault_ids       = [module.key_vault.id]
  tags                = local.custom_tags
  depends_on          = [null_resource.test_dependencies]
}

# Terraform output
output "data_factory_tests" {
  value = {
    test_data_factory_defaults = {
      id                        = module.test_data_factory_defaults.id
      name                      = module.test_data_factory_defaults.name
      principal_id              = module.test_data_factory_defaults.principal_id
      key_vault_linked_services = module.test_data_factory_defaults.key_vault_linked_services
    }
    test_data_factory_with_key_vault = {
      id                        = module.test_data_factory_with_key_vault.id
      name                      = module.test_data_factory_with_key_vault.name
      principal_id              = module.test_data_factory_with_key_vault.principal_id
      key_vault_linked_services = module.test_data_factory_with_key_vault.key_vault_linked_services
    }
  }
}
