/**
* Syncs a list of groups from the Azure AD Tenant to the Databricks workspace.
* The groups and users/service principals must already exist in the Azure AD Tenant.
* Does not support nested groups.
* This module will control both the groups and members:
*   if a user is removed from all groups it will also be removed from the Databricks workspace
*/

# Get the groups details from the Azure AD Tenant
data "azuread_group" "all" {
  for_each         = toset(var.groups)
  display_name     = each.key
  security_enabled = true
}

# Create a flat list with all members of all groups (uses a set to eliminate duplicates)
locals {
  all_principals = toset(flatten([for group in values(data.azuread_group.all) : group.members] ))
}

# Get the users details from the Azure AD Tenant
# Uses ignore_missing to ignore any service principals
data "azuread_users" "members" {
  object_ids     = local.all_principals
  ignore_missing = true
}

# Create a list with all service principals using the difference between the list of all members and the list of users
# This will not support nested groups
locals {
  service_principals_list = toset(setsubtract(local.all_principals, data.azuread_users.members.object_ids))
}

# Get the service principals details from the Azure AD Tenant
data "azuread_service_principals" "members" {
  object_ids = local.service_principals_list
}

# Transform the users list into a map with the object_id as the key
locals {
  users = {
    for user in data.azuread_users.members.users :
    user.object_id => user
  }
  service_principals = {
    for sp in data.azuread_service_principals.members.service_principals :
    sp.object_id => sp
  }
}

# Add the users to the Databricks workspace
resource "databricks_user" "users" {
  for_each                 = local.users
  user_name                = lower(local.users[each.key]["user_principal_name"])
  display_name             = local.users[each.key]["display_name"]
  external_id              = each.key
  active                   = true
  force                    = true
  disable_as_user_deletion = true
}

# Add the service principals to the Databricks workspace
resource "databricks_service_principal" "sps" {
  for_each                 = local.service_principals
  application_id           = lower(local.service_principals[each.key]["application_id"])
  display_name             = local.service_principals[each.key]["display_name"]
  external_id              = each.key
  active                   = true
  force                    = true
  disable_as_user_deletion = true
}

# Add the groups to the Databricks workspace
resource "databricks_group" "groups" {
  for_each                   = toset(var.groups)
  display_name               = data.azuread_group.all[each.key].display_name
  workspace_access           = contains(var.workspace_access, each.key) ? true : false
  databricks_sql_access      = contains(var.databricks_sql_access, each.key) ? true : false
  allow_cluster_create       = contains(var.allow_cluster_create, each.key) ? true : false
  allow_instance_pool_create = contains(var.allow_instance_pool_create, each.key) ? true : false
  force                      = true
}

# Create a flat list with all of the valid pairs of databricks_group_id - databricks_principal_id
locals {
  group_members = flatten([
    for group, details in data.azuread_group.all : [
      for member in details["members"] : {
        group  = databricks_group.groups[group].id,
        member = merge(databricks_user.users, databricks_service_principal.sps)[member].id
      }
    ]
  ])
}

# Set all of the Databricks groups members
resource "databricks_group_member" "all" {
  count     = length(local.group_members)
  group_id  = local.group_members[count.index]["group"]
  member_id = local.group_members[count.index]["member"]
}
