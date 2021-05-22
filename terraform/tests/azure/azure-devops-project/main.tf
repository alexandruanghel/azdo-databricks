/**
* Tests for the azure-devops-project module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 0.14"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.60"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

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
  project_defaults    = "tftest-project-default-${random_string.suffix.result}"
  project_with_github = "tftest-project-github-${random_string.suffix.result}"
  project_with_arm    = "tftest-project-arm-${random_string.suffix.result}"
  project_mixed       = "tftest-project-mixed-${random_string.suffix.result}"
  github_endpoint     = "tftest-endpoint-git-${random_string.suffix.result}"
  arm_endpoint1       = "tftest-endpoint1-arm-${random_string.suffix.result}"
  arm_endpoint2       = "tftest-endpoint2-arm-${random_string.suffix.result}"
  service_principal   = "tftestspn-${random_string.suffix.result}"
}

# Create the test app registration
resource "azuread_application" "test_app" {
  display_name    = "TF Test ${local.service_principal}"
  identifier_uris = ["http://${local.service_principal}"]
}

# Create the test service principal
resource "azuread_service_principal" "test_sp" {
  application_id = azuread_application.test_app.application_id
  depends_on     = [azuread_application.test_app]
}

resource "azuread_service_principal_password" "test_sp" {
  service_principal_id = azuread_service_principal.test_sp.object_id
  description          = "tftest"
  value                = "Secret${random_string.suffix.result}"
  end_date_relative    = "24h"
}

# Build an Azure DevOps project with default parameters
module "test_project_defaults" {
  source       = "../../../modules/azure/azure-devops-project"
  project_name = local.project_defaults
}

# Build an Azure DevOps project with a GitHub service connection
module "test_project_with_github_endpoint" {
  source           = "../../../modules/azure/azure-devops-project"
  project_name     = local.project_with_github
  github_endpoints = [local.github_endpoint]
  github_pat       = random_string.suffix.result
}

# Build an Azure DevOps project with an AzureRM service connection
module "test_project_with_arm_endpoint" {
  source        = "../../../modules/azure/azure-devops-project"
  project_name  = local.project_with_arm
  arm_endpoints = [{
    name          = local.arm_endpoint1
    client_id     = azuread_service_principal.test_sp.application_id
    client_secret = azuread_service_principal_password.test_sp.value
  }]
}

# Build an Azure DevOps project with a GitHub service connection and two AzureRM service connections
module "test_project_mixed" {
  source           = "../../../modules/azure/azure-devops-project"
  project_name     = local.project_mixed
  github_endpoints = [local.github_endpoint]
  github_pat       = random_string.suffix.result
  arm_endpoints    = [{
    name          = local.arm_endpoint1
    client_id     = azuread_service_principal.test_sp.application_id
    client_secret = azuread_service_principal_password.test_sp.value
  },{
    name          = local.arm_endpoint2
    client_id     = azuread_service_principal.test_sp.application_id
    client_secret = azuread_service_principal_password.test_sp.value
  }]
}

# Terraform output
output "azure_devops_project_tests" {
  sensitive = true
  value = {
    test_project_defaults = {
      id        = module.test_project_defaults.id
      name      = module.test_project_defaults.name
      endpoints = module.test_project_defaults.service_endpoints
    }
    test_project_with_github_endpoint = {
      id        = module.test_project_with_github_endpoint.id
      name      = module.test_project_with_github_endpoint.name
      endpoints = module.test_project_with_github_endpoint.service_endpoints
    }
    test_project_with_arm_endpoint = {
      id        = module.test_project_with_arm_endpoint.id
      name      = module.test_project_with_arm_endpoint.name
      endpoints = module.test_project_with_arm_endpoint.service_endpoints
    }
    test_project_mixed = {
      id        = module.test_project_mixed.id
      name      = module.test_project_mixed.name
      endpoints = module.test_project_mixed.service_endpoints
    }
  }
}
