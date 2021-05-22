/**
* Tests for the key-vault module
*/
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

terraform {
  required_version = "~> 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.60"
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
  resource_group_name = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  key_vault_defaults  = "tftest-akv-${random_string.suffix.result}"
  key_vault_custom    = "tftest-akvc-${random_string.suffix.result}"
  custom_tags         = { Purpose = "Terraform-test-${random_string.suffix.result}" }
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
  triggers   = {
    rg = module.test_resource_group.id
  }
  depends_on = [module.test_resource_group]
}

# Build a Key Vault with default parameters
module "test_key_vault_defaults" {
  source              = "../../../modules/azure/key-vault"
  resource_group_name = local.resource_group_name
  key_vault_name      = local.key_vault_defaults
  depends_on          = [null_resource.test_dependencies]
}

# Build a Key Vault with custom parameters
module "test_key_vault_custom" {
  source                     = "../../../modules/azure/key-vault"
  azure_location             = var.azure_location
  resource_group_name        = local.resource_group_name
  key_vault_name             = local.key_vault_custom
  sku_name                   = "premium"
  soft_delete_retention_days = 10
  tags                       = local.custom_tags
  depends_on                 = [null_resource.test_dependencies]
}

# Terraform output
output "key_vault_tests" {
  value = {
    test_key_vault_defaults = {
      id     = module.test_key_vault_defaults.id
      name   = module.test_key_vault_defaults.name
      uri    = module.test_key_vault_defaults.uri
      policy = module.test_key_vault_defaults.policy
    }
    test_key_vault_custom = {
      id     = module.test_key_vault_custom.id
      name   = module.test_key_vault_custom.name
      uri    = module.test_key_vault_custom.uri
      policy = module.test_key_vault_custom.policy
    }
  }
}
