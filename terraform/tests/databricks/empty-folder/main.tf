/**
* Tests for the empty-folder module
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
    databricks = {
      source  = "databrickslabs/databricks"
      version = "~> 0.3"
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

# Create a random uuid to be used as the service principal client id
resource "random_uuid" "sp_client_id" {}

# Set the rest of the test variables using the random string
locals {
  resource_group_name       = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  databricks_workspace_name = var.databricks_workspace_name == null ? "tftest-ws-${random_string.suffix.result}" : var.databricks_workspace_name
  folder_defaults        = "/TF Test Default ${random_string.suffix.result}"
  folder_with_users      = "/TF Test Users ${random_string.suffix.result}"
  folder_with_everything = "/TF Test All ${random_string.suffix.result}"
  user_1_name            = "user1.${random_string.suffix.result}@example.com"
  user_2_name            = "user2.${random_string.suffix.result}@example.com"
  group_name             = "TF Test ${random_string.suffix.result}"
}

# Create an empty Resource Group to be used by the rest of the resources
resource "azurerm_resource_group" "test" {
  name     = local.resource_group_name
  location = var.azure_location
}

# Build a Databricks workspace with default parameters
module "test_databricks_workspace_defaults" {
  source              = "../../../modules/azure/databricks-workspace"
  resource_group_name = azurerm_resource_group.test.name
  workspace_name      = local.databricks_workspace_name
}

# Get information about the Databricks workspace
data "azurerm_databricks_workspace" "main" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group_name
  depends_on          = [module.test_databricks_workspace_defaults]
}

# Configure the Databricks Terraform provider
provider "databricks" {
  azure_workspace_resource_id = data.azurerm_databricks_workspace.main.id
}

# Build a test Group
module "test_group" {
  source               = "../../../modules/databricks/databricks-principal"
  principal_type       = "group"
  principal_identifier = local.group_name
}

# Build two test Users
module "test_user_1" {
  source               = "../../../modules/databricks/databricks-principal"
  principal_type       = "user"
  principal_identifier = local.user_1_name
}

module "test_user_2" {
  source               = "../../../modules/databricks/databricks-principal"
  principal_type       = "user"
  principal_identifier = local.user_2_name
}

# Build a test Service Principal
module "test_sp" {
  source               = "../../../modules/databricks/databricks-principal"
  principal_type       = "service_principal"
  principal_identifier = random_uuid.sp_client_id.result
}

# Marker for test dependencies
resource "null_resource" "test_dependencies" {
  triggers   = {
    ws     = module.test_databricks_workspace_defaults.id
    users  = join(",", [module.test_user_1.id, module.test_user_2.id])
    sps    = join(",", [module.test_sp.id])
    groups = join(",", [module.test_group.id])
  }
  depends_on = [
    module.test_databricks_workspace_defaults,
    module.test_user_1,
    module.test_user_2,
    module.test_sp,
    module.test_group
  ]
}

# Create a folder with default parameters
module "test_folder_defaults" {
  source      = "../../../modules/databricks/empty-folder"
  folder_path = local.folder_defaults
  depends_on  = [null_resource.test_dependencies]
}

# Create a folder with two users
module "test_folder_with_users" {
  source      = "../../../modules/databricks/empty-folder"
  folder_path = local.folder_with_users
  permissions = [{principal = local.user_1_name, type = "user", permission = "CAN_READ"},
                 {principal = local.user_2_name, type = "user", permission = "CAN_READ"}]
  depends_on  = [null_resource.test_dependencies]
}

# Create a folder with users, groups, service principals
module "test_folder_with_everything" {
  source      = "../../../modules/databricks/empty-folder"
  folder_path = local.folder_with_everything
  permissions = [{principal = local.user_1_name, type = "user", permission = "CAN_READ"},
                 {principal = local.user_2_name, type = "user", permission = "CAN_MANAGE"},
                 {principal = random_uuid.sp_client_id.result, type = "service_principal", permission = "CAN_RUN"},
                 {principal = local.group_name, type = "group", permission = "CAN_EDIT"}]
  depends_on  = [null_resource.test_dependencies]
}

# Terraform output
output "empty_folder_tests" {
  value = {
    test_folder_defaults = {
      id          = module.test_folder_defaults.id
      details     = module.test_folder_defaults.details
      permissions = module.test_folder_defaults.permissions
    }
    test_folder_with_users = {
      id          = module.test_folder_with_users.id
      details     = module.test_folder_with_users.details
      permissions = module.test_folder_with_users.permissions
    }
    test_folder_with_everything = {
      id          = module.test_folder_with_everything.id
      details     = module.test_folder_with_everything.details
      permissions = module.test_folder_with_everything.permissions
    }
  }
}
