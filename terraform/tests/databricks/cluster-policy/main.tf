/**
* Tests for the cluster-policy module
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
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.24"
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

# Create a random uuid to be used as the service principal client id
resource "random_uuid" "sp_client_id" {}

# Set the rest of the test variables using the random string
locals {
  resource_group_name       = var.resource_group_name == null ? "tftest-rg-${random_string.suffix.result}" : var.resource_group_name
  databricks_workspace_name = var.databricks_workspace_name == null ? "tftest-ws-${random_string.suffix.result}" : var.databricks_workspace_name
  policy_defaults           = "TF Test Default ${random_string.suffix.result}"
  policy_with_users         = "TF Test Users ${random_string.suffix.result}"
  policy_with_arguments     = "TF Test Arguments ${random_string.suffix.result}"
  policy_with_overrides     = "TF Test Overrides ${random_string.suffix.result}"
  policy_with_jsonfile      = "TF Test Json ${random_string.suffix.result}"
  policy_with_everything    = "TF Test Everything ${random_string.suffix.result}"
  user_1_name               = "user1.${random_string.suffix.result}@example.com"
  user_2_name               = "user2.${random_string.suffix.result}@example.com"
  group_name                = "TF Test ${random_string.suffix.result}"
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

# Marker for test dependencies
resource "null_resource" "test_dependencies" {
  triggers = {
    uuid = random_uuid.sp_client_id.id
    ws   = module.test_databricks_workspace_defaults.id
  }
  depends_on = [
    random_uuid.sp_client_id,
    module.test_databricks_workspace_defaults
  ]
}

# Get information about the Databricks workspace
data "azurerm_databricks_workspace" "main" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group_name
  depends_on          = [module.test_databricks_workspace_defaults]
}

# Configure the Databricks Terraform provider
provider "databricks" {
  host = data.azurerm_databricks_workspace.main.workspace_url
}

# Build a test Group
resource "databricks_group" "groups" {
  display_name = local.group_name
  force        = true
  depends_on   = [null_resource.test_dependencies]
}


# Build two test Users
resource "databricks_user" "test_user_1" {
  user_name  = local.user_1_name
  depends_on = [null_resource.test_dependencies]
  active     = true
  force      = true
}

resource "databricks_user" "test_user_2" {
  user_name  = local.user_2_name
  active     = true
  force      = true
  depends_on = [null_resource.test_dependencies]
}

# Build a test Service Principal
resource "databricks_service_principal" "test_sp" {
  application_id = random_uuid.sp_client_id.result
  active         = true
  force          = true
  depends_on     = [null_resource.test_dependencies]
}

# Create a policy with default parameters
module "test_policy_defaults" {
  source      = "../../../modules/databricks/cluster-policy"
  policy_name = local.policy_defaults
  depends_on  = [null_resource.test_dependencies]
}

# Create a policy with default parameters and two users
module "test_policy_with_users" {
  source      = "../../../modules/databricks/cluster-policy"
  policy_name = local.policy_with_users
  CAN_USE     = [
    { principal = local.user_1_name, type = "user" },
    { principal = local.user_2_name, type = "user" }
  ]
  depends_on = [null_resource.test_dependencies, databricks_user.test_user_1, databricks_user.test_user_2]
}

# Create a policy with default policy arguments changed
module "test_policy_with_arguments" {
  source                          = "../../../modules/databricks/cluster-policy"
  policy_name                     = local.policy_with_arguments
  default_spark_version_regex     = "13.3.x-([cg]pu-ml-)?scala2.12"
  default_autotermination_minutes = 10
  default_cluster_log_path        = "dbfs:/tmp/cluster-logs"
  depends_on                      = [null_resource.test_dependencies]
}

# Create a policy with overrides as arguments
module "test_policy_with_overrides" {
  source                      = "../../../modules/databricks/cluster-policy"
  policy_name                 = local.policy_with_overrides
  default_spark_version_regex = "13.3.x-([cg]pu-ml-)?scala2.12"
  policy_overrides_object     = {
    "spark_version" : {
      "type" : "fixed",
      "value" : "13.3.x-scala2.12",
      "hidden" : false
    },
    "autotermination_minutes" : {
      "type" : "fixed",
      "value" : 60,
      "hidden" : true
    },
    "dbus_per_hour" : {
      "type" : "range",
      "maxValue" : 2
    }
  }
  depends_on = [null_resource.test_dependencies]
}

# Create a policy with overrides as json file
module "test_policy_with_jsonfile" {
  source                      = "../../../modules/databricks/cluster-policy"
  policy_name                 = local.policy_with_jsonfile
  default_spark_version_regex = "13.3.x-([cg]pu-ml-)?scala2.12"
  policy_overrides_file       = "policy.json"
  depends_on                  = [null_resource.test_dependencies]
}

# Create a folder with users, groups, service principals
module "test_policy_with_everything" {
  source      = "../../../modules/databricks/cluster-policy"
  policy_name = local.policy_with_everything
  CAN_USE     = [
    { principal = local.user_1_name, type = "user" },
    { principal = local.user_2_name, type = "user" },
    { principal = random_uuid.sp_client_id.result, type = "service_principal" },
    { principal = local.group_name, type = "group" }
  ]
  default_spark_version_regex = "13.3.x-([cg]pu-ml-)?scala2.12"
  policy_overrides_file       = "policy.json"
  policy_overrides_object     = {
    "spark_version" : {
      "type" : "fixed",
      "value" : "13.3.x-scala2.12",
      "hidden" : false
    }
  }
  depends_on = [
    null_resource.test_dependencies,
    databricks_user.test_user_1,
    databricks_user.test_user_2,
    databricks_service_principal.test_sp,
    databricks_group.groups
  ]
}

# Terraform output
output "cluster_policy_tests" {
  value = {
    test_policy_defaults = {
      id          = module.test_policy_defaults.id
      details     = module.test_policy_defaults.details
      permissions = module.test_policy_defaults.permissions
    }
    test_policy_with_users = {
      id          = module.test_policy_with_users.id
      details     = module.test_policy_with_users.details
      permissions = module.test_policy_with_users.permissions
    }
    test_policy_with_arguments = {
      id          = module.test_policy_with_arguments.id
      details     = module.test_policy_with_arguments.details
      permissions = module.test_policy_with_arguments.permissions
    }
    test_policy_with_overrides = {
      id          = module.test_policy_with_overrides.id
      details     = module.test_policy_with_overrides.details
      permissions = module.test_policy_with_overrides.permissions
    }
    test_policy_with_jsonfile = {
      id          = module.test_policy_with_jsonfile.id
      details     = module.test_policy_with_jsonfile.details
      permissions = module.test_policy_with_jsonfile.permissions
    }
    test_policy_with_everything = {
      id          = module.test_policy_with_everything.id
      details     = module.test_policy_with_everything.details
      permissions = module.test_policy_with_everything.permissions
    }
  }
}
