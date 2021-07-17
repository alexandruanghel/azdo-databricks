/**
* Tests for the storage-account module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.68"
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
  resource_group_name      = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  storage_account_defaults = "tftestdefaults${random_string.suffix.result}"
  storage_account_blob     = "tftestblob${random_string.suffix.result}"
  storage_account_adls     = "tftestadls${random_string.suffix.result}"
  custom_tags              = { Purpose = "Terraform-test-${random_string.suffix.result}" }
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

# Build a Storage Account with default parameters
module "test_storage_account_defaults" {
  source               = "../../../modules/azure/storage-account"
  resource_group_name  = local.resource_group_name
  storage_account_name = local.storage_account_defaults
  depends_on           = [null_resource.test_dependencies]
}

# Build a Blob Storage Account with 2 containers
module "test_storage_account_blob" {
  source               = "../../../modules/azure/storage-account"
  azure_location       = var.azure_location
  resource_group_name  = local.resource_group_name
  storage_account_name = local.storage_account_blob
  storage_containers   = ["container1", "container2"]
  tags                 = local.custom_tags
  depends_on           = [null_resource.test_dependencies]
}

# Build a Data Lake Gen 2 Storage Account with 2 filesystems
module "test_storage_account_adls" {
  source                 = "../../../modules/azure/storage-account"
  azure_location         = var.azure_location
  resource_group_name    = local.resource_group_name
  storage_account_name   = local.storage_account_adls
  hierarchical_namespace = true
  storage_containers     = ["fs1", "fs2"]
  tags                   = local.custom_tags
  depends_on             = [null_resource.test_dependencies]
}

# Terraform output
output "storage_account_tests" {
  value = {
    test_storage_account_defaults = {
      id       = module.test_storage_account_defaults.id
      name     = module.test_storage_account_defaults.name
    }
    test_storage_account_blob = {
      id       = module.test_storage_account_blob.id
      name     = module.test_storage_account_blob.name
    }
    test_storage_account_adls = {
      id       = module.test_storage_account_adls.id
      name     = module.test_storage_account_adls.name
    }
  }
}
