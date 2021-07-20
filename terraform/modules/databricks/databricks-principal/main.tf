/**
* Adds a principal (user, group or service_principal) to the Databricks workspace with an optional group membership.
*/

# Get the groups details from the Databricks workspace
data "databricks_group" "groups" {
  count        = length(var.groups)
  display_name = var.groups[count.index]
}

resource "databricks_user" "user" {
  count                      = var.principal_type == "user" ? 1 : 0
  user_name                  = var.principal_identifier
  display_name               = var.display_name
  allow_cluster_create       = var.allow_cluster_create
  allow_instance_pool_create = var.allow_instance_pool_create
  active                     = true
}

resource "databricks_service_principal" "sp" {
  count                      = var.principal_type == "service_principal" ? 1 : 0
  application_id             = var.principal_identifier
  display_name               = var.display_name == "" ? "sp-${var.principal_identifier}" : var.display_name
  allow_cluster_create       = var.allow_cluster_create
  allow_instance_pool_create = var.allow_instance_pool_create
  active                     = true
}

resource "databricks_group" "group" {
  count                      = var.principal_type == "group" ? 1 : 0
  display_name               = var.principal_identifier
  allow_cluster_create       = var.allow_cluster_create
  allow_instance_pool_create = var.allow_instance_pool_create
}

resource "databricks_group_member" "groups" {
  count     = length(var.groups)
  group_id  = data.databricks_group.groups[count.index].id
  member_id = coalescelist(flatten([databricks_user.user, databricks_service_principal.sp, databricks_group.group]))[0].id
}
