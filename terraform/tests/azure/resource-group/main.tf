/**
* Tests for the resource-group module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 1.1"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2"
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
  resource_group_defaults   = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  resource_group_with_roles = "tftest-rg-roles-${random_string.suffix.result}"
  spn                       = "tftestspn1${random_string.suffix.result}"
  custom_tags               = { Purpose = "Terraform-test-${random_string.suffix.result}" }
}

# Create a test app registration
resource "azuread_application" "test_app" {
  display_name    = "TF Test ${local.spn}"
  identifier_uris = ["api://${local.spn}"]
}

# Create a test service principal
resource "azuread_service_principal" "test_sp" {
  application_id = azuread_application.test_app.application_id
  depends_on     = [azuread_application.test_app]
}

# Build a Resource Group with default parameters
module "test_resource_group_defaults" {
  source              = "../../../modules/azure/resource-group"
  azure_location      = var.azure_location
  resource_group_name = local.resource_group_defaults
}

# Build a Resource Group with roles
module "test_resource_group_with_roles" {
  source              = "../../../modules/azure/resource-group"
  azure_location      = var.azure_location
  resource_group_name = local.resource_group_with_roles
  readers             = [azuread_service_principal.test_sp.object_id]
  contributors        = [azuread_service_principal.test_sp.object_id]
  owners              = [azuread_service_principal.test_sp.object_id]
  tags                = local.custom_tags
}

# Terraform output
output "resource_group_tests" {
  value = {
    test_resource_group_defaults = {
      id       = module.test_resource_group_defaults.id
      name     = module.test_resource_group_defaults.name
      location = module.test_resource_group_defaults.location
    }
    test_resource_group_with_roles = {
      id       = module.test_resource_group_with_roles.id
      name     = module.test_resource_group_with_roles.name
      location = module.test_resource_group_with_roles.location
    }
  }
}
