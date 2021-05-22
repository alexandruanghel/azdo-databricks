/**
* Tests for the azure-groups-sync module
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

# Set the rest of the test variables using the random string
locals {
  resource_group_name       = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  databricks_workspace_name = var.databricks_workspace_name == null ? "tftest-ws-${random_string.suffix.result}" : var.databricks_workspace_name
  group_empty            = "TF Test Empty ${random_string.suffix.result}"
  group_with_one_user    = "TF Test User ${random_string.suffix.result}"
  group_with_one_sp      = "TF Test SP ${random_string.suffix.result}"
  group_with_one_of_each = "TF Test One Each ${random_string.suffix.result}"
  group_mixed1           = "TF Test Mixed1 ${random_string.suffix.result}"
  group_mixed2           = "TF Test Mixed2 ${random_string.suffix.result}"
  user1 = "tftestuser1${random_string.suffix.result}"
  user2 = "tftestuser2${random_string.suffix.result}"
  user3 = "tftestuser3${random_string.suffix.result}"
  user4 = "tftestuser4${random_string.suffix.result}"
  users = [local.user1, local.user2, local.user3, local.user4]
  spn1  = "tftestspn1${random_string.suffix.result}"
  spn2  = "tftestspn2${random_string.suffix.result}"
  spn3  = "tftestspn3${random_string.suffix.result}"
  spn4  = "tftestspn4${random_string.suffix.result}"
  sps   = [local.spn1, local.spn2, local.spn3, local.spn4]
}

# Create an empty Resource Group to be used by the rest of the resources
data "azurerm_client_config" "current" {}

module "test_resource_group" {
  source              = "../../../modules/azure/resource-group"
  azure_location      = var.azure_location
  resource_group_name = local.resource_group_name
  owners              = [data.azurerm_client_config.current.object_id]
}

# Build a Databricks workspace with default parameters
module "test_databricks_workspace_defaults" {
  source              = "../../../modules/azure/databricks-workspace"
  resource_group_name = module.test_resource_group.name
  workspace_name      = local.databricks_workspace_name
}

# Get information about the Azure AD default domain
data "azuread_domains" "aad_domains" {
  only_default = true
}

# Create the test users
resource "azuread_user" "test_users" {
  count               = length(local.users)
  user_principal_name = "${local.users[count.index]}@${data.azuread_domains.aad_domains.domains[0].domain_name}"
  display_name        = "TF Test ${local.users[count.index]}"
  password            = "Secret${random_string.suffix.result}!"
}

# Create the test app registrations
resource "azuread_application" "test_apps" {
  count           = length(local.sps)
  display_name    = "TF Test ${local.sps[count.index]}"
  identifier_uris = ["http://${local.sps[count.index]}"]
}

# Create the test service principals
resource "azuread_service_principal" "test_sps" {
  count          = length(azuread_application.test_apps)
  application_id = azuread_application.test_apps[count.index].application_id
  depends_on     = [azuread_application.test_apps]
}

# Create an empty group
resource "azuread_group" "empty" {
  display_name            = local.group_empty
  prevent_duplicate_names = true
}

# Create a group with one user
resource "azuread_group" "one_user" {
  display_name            = local.group_with_one_user
  prevent_duplicate_names = true
  members = [
    azuread_user.test_users[0].object_id
  ]
}

# Create a group with one service principal
resource "azuread_group" "one_sp" {
  display_name            = local.group_with_one_sp
  prevent_duplicate_names = true
  members = [
    azuread_service_principal.test_sps[0].object_id
  ]
}

# Create a group with one user and one service principal
resource "azuread_group" "one_of_each" {
  display_name            = local.group_with_one_of_each
  prevent_duplicate_names = true
  members = [
    azuread_user.test_users[1].object_id,
    azuread_service_principal.test_sps[1].object_id
  ]
}

# Create a group with one user and two service principals
resource "azuread_group" "mixed1" {
  display_name            = local.group_mixed1
  prevent_duplicate_names = true
  members = [
    azuread_user.test_users[2].object_id,
    azuread_service_principal.test_sps[2].object_id,
    azuread_service_principal.test_sps[3].object_id
  ]
}

# Create a group with two users and one service principal
resource "azuread_group" "mixed2" {
  display_name            = local.group_mixed2
  prevent_duplicate_names = true
  members = [
    azuread_user.test_users[2].object_id,
    azuread_user.test_users[3].object_id,
    azuread_service_principal.test_sps[2].object_id
  ]
}

# Marker for test dependencies
resource "null_resource" "test_dependencies" {
  triggers = {
    ws     = module.test_databricks_workspace_defaults.id
    users  = join(",", azuread_user.test_users.*.id)
    sps    = join(",", azuread_service_principal.test_sps.*.id)
    groups = join(",", [azuread_group.empty.id,
                        azuread_group.one_user.id,
                        azuread_group.one_sp.id,
                        azuread_group.one_of_each.id,
                        azuread_group.mixed1.id,
                        azuread_group.mixed2.id])
  }
  depends_on = [
    module.test_databricks_workspace_defaults,
    azuread_user.test_users,
    azuread_service_principal.test_sps,
    azuread_group.empty,
    azuread_group.one_user,
    azuread_group.one_sp,
    azuread_group.one_of_each,
    azuread_group.mixed1,
    azuread_group.mixed2
  ]
}

# Get information about the Databricks workspace
data "azurerm_databricks_workspace" "main" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group_name
  depends_on          = [null_resource.test_dependencies]
}

# Configure the Databricks Terraform provider
provider "databricks" {
  azure_workspace_resource_id = data.azurerm_databricks_workspace.main.id
}

# Sync an empty group
module "test_group_empty" {
  source     = "../../../modules/databricks/azure-groups-sync"
  groups     = [azuread_group.empty.display_name]
  depends_on = [null_resource.test_dependencies]
}

# Sync a group with one user
module "test_group_one_user" {
  source     = "../../../modules/databricks/azure-groups-sync"
  groups     = [azuread_group.one_user.display_name]
  depends_on = [null_resource.test_dependencies]
}

# Sync a group with one service principal
module "test_group_one_sp" {
  source     = "../../../modules/databricks/azure-groups-sync"
  groups     = [azuread_group.one_sp.display_name]
  depends_on = [null_resource.test_dependencies]
}

# Sync a group with one user and one service principal
module "test_group_one_of_each" {
  source               = "../../../modules/databricks/azure-groups-sync"
  groups               = [azuread_group.one_of_each.display_name]
  allow_cluster_create = [azuread_group.one_of_each.display_name]
  depends_on           = [null_resource.test_dependencies]
}

# Sync two groups with mixed users and service principals including overlaps
module "test_group_mixed" {
  source                     = "../../../modules/databricks/azure-groups-sync"
  groups                     = [azuread_group.mixed1.display_name, azuread_group.mixed2.display_name]
  allow_cluster_create       = [azuread_group.mixed1.display_name]
  allow_instance_pool_create = [azuread_group.mixed2.display_name]
  depends_on                 = [null_resource.test_dependencies]
}

# Terraform output
output "azure_groups_sync_tests" {
  value = {
    test_group_empty = {
      group_name = azuread_group.empty.display_name
      object_id  = azuread_group.empty.object_id
      members    = azuread_group.empty.members
      databricks_users              = module.test_group_empty.databricks_users
      databricks_service_principals = module.test_group_empty.databricks_service_principals
      databricks_groups             = module.test_group_empty.databricks_groups
      databricks_groups_members     = module.test_group_empty.databricks_groups_membership
    }
    test_group_one_user = {
      group_name = azuread_group.one_user.display_name
      object_id  = azuread_group.one_user.object_id
      members    = azuread_group.one_user.members
      databricks_users              = module.test_group_one_user.databricks_users
      databricks_service_principals = module.test_group_one_user.databricks_service_principals
      databricks_groups             = module.test_group_one_user.databricks_groups
      databricks_groups_members     = module.test_group_one_user.databricks_groups_membership
    }
    test_group_one_sp = {
      group_name = azuread_group.one_sp.display_name
      object_id  = azuread_group.one_sp.object_id
      members    = azuread_group.one_sp.members
      databricks_users              = module.test_group_one_sp.databricks_users
      databricks_service_principals = module.test_group_one_sp.databricks_service_principals
      databricks_groups             = module.test_group_one_sp.databricks_groups
      databricks_groups_members     = module.test_group_one_sp.databricks_groups_membership
    }
    test_group_one_of_each = {
      group_name = azuread_group.one_of_each.display_name
      object_id  = azuread_group.one_of_each.object_id
      members    = azuread_group.one_of_each.members
      databricks_users              = module.test_group_one_of_each.databricks_users
      databricks_service_principals = module.test_group_one_of_each.databricks_service_principals
      databricks_groups             = module.test_group_one_of_each.databricks_groups
      databricks_groups_members     = module.test_group_one_of_each.databricks_groups_membership
    }
    test_group_mixed = {
      group_name1 = azuread_group.mixed1.display_name
      object_id1  = azuread_group.mixed1.object_id
      members1    = azuread_group.mixed1.members
      group_name2 = azuread_group.mixed2.display_name
      object_id2  = azuread_group.mixed2.object_id
      members2    = azuread_group.mixed2.members
      databricks_users              = module.test_group_mixed.databricks_users
      databricks_service_principals = module.test_group_mixed.databricks_service_principals
      databricks_groups             = module.test_group_mixed.databricks_groups
      databricks_groups_members     = module.test_group_mixed.databricks_groups_membership
    }
  }
}
