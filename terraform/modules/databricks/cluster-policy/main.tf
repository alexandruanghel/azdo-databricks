/**
* Creates a Databricks cluster policy with optional CAN_USE permissions.
* The policy will be created by merging the following sources (in this order):
*   1) a default policy definition with optional variables
*   2) a policy json file
*   3) policy overrides as a Terraform object
*/

# Define default rules that will be applied to every policy unless overridden
locals {
  default_policy = {
    "spark_version" : {
      "type" : "regex",
      "pattern" : var.default_spark_version_regex,
      "hidden" : false
    },
    "autotermination_minutes" : {
      "type" : "fixed",
      "value" : var.default_autotermination_minutes,
      "hidden" : false
    },
    "cluster_log_conf.path" : {
      "type" : "unlimited",
      "defaultValue" : var.default_cluster_log_path,
      "isOptional" : false,
      "hidden" : false
    },
    "cluster_log_conf.type" : {
      "type" : "fixed",
      "value" : "DBFS",
      "hidden" : false
    },
    "custom_tags.PolicyName" : {
      "type" : "fixed",
      "value" : var.policy_name,
      "hidden" : false
    },
    "docker_image.url" : {
      "type" : "forbidden",
      "hidden" : true
    }
  }
}

# Read the policy json file if one was defined
data "local_file" "policy_definition" {
  count    = try(fileexists(var.policy_overrides_file), false) ? 1 : 0
  filename = var.policy_overrides_file
}

resource "databricks_cluster_policy" "this" {
  name = var.policy_name

  # Merge the local default rules with the other policy overrides passed from the variables
  definition = jsonencode(merge(local.default_policy,
    try(jsondecode(base64decode(data.local_file.policy_definition[0].content_base64)), {}),
    var.policy_overrides_object))
}

# Create the policy
resource "databricks_permissions" "policy" {
  count             = length(var.CAN_USE) > 0 ? 1 : 0
  cluster_policy_id = databricks_cluster_policy.this.id

  dynamic "access_control" {
    for_each = toset(var.CAN_USE)
    content {
      user_name              = access_control.value.type == "user" ? access_control.value.principal : ""
      group_name             = access_control.value.type == "group" ? access_control.value.principal : ""
      service_principal_name = access_control.value.type == "service_principal" ? access_control.value.principal : ""
      permission_level       = "CAN_USE"
    }
  }
}
