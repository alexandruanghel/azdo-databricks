/**
* Tests for the service-principal module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 1.4"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# Minimum of variables required for the test
variable "azure_location" { default = "westeurope" }

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
  spn_defaults        = "tftestspn-defaults-${random_string.suffix.result}"
  spn_api_permissions = "tftestspn-api-${random_string.suffix.result}"
  spn_with_owner      = "tftestspn-owner-${random_string.suffix.result}"
}

# Marker for test dependencies
resource "null_resource" "test_dependencies" {
  triggers   = {
    random_string = random_string.suffix.result
  }
  depends_on = [random_string.suffix]
}

# Create a Service Principal with defaults
module "test_sp_defaults" {
  source = "../../../modules/azure/service-principal"
  name   = local.spn_defaults
}

# Create a Service Principal with API Permissions
module "test_sp_api_permissions" {
  source          = "../../../modules/azure/service-principal"
  name            = local.spn_api_permissions
  api_permissions = ["User.Read.All", "GroupMember.Read.All", "Application.Read.All"]
}

# Create a Service Principal with an Owner
module "test_sp_with_owner" {
  source = "../../../modules/azure/service-principal"
  name   = local.spn_with_owner
  owners = [module.test_sp_defaults.object_id]
}

# Terraform output
output "service_principal_tests" {
  value = {
    test_sp_defaults = {
      object_id      = module.test_sp_defaults.object_id
      application_id = module.test_sp_defaults.application_id
    }
    test_sp_api_permissions = {
      object_id      = module.test_sp_api_permissions.object_id
      application_id = module.test_sp_api_permissions.application_id
    }
    test_sp_with_owner = {
      object_id      = module.test_sp_with_owner.object_id
      application_id = module.test_sp_with_owner.application_id
    }
  }
}
