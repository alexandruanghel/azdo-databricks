## Description

Syncs a list of groups from the Azure AD Tenant to the Databricks workspace.

The groups and users/service principals must already exist in the Azure AD Tenant.

Does not support nested groups.

This module will control both the groups and members:

- if a user is removed from all groups it will also be removed from the Databricks workspace

## Inputs

| Name                       | Description                                                          | Type           | Default | Required |
|----------------------------|----------------------------------------------------------------------|----------------|---------|:--------:|
| groups                     | The list of groups to be synced                                      | `list(string)` | n/a     |   yes    |
| allow_cluster_create       | A sublist of groups that should have cluster create privileges       | `list(string)` | `[]`    |    no    |
| allow_instance_pool_create | A sublist of groups that should have instance pool create privileges | `list(string)` | `[]`    |    no    |

## Outputs

| Name                          | Description                                         |
|-------------------------------|-----------------------------------------------------|
| databricks_users              | The details of the Databricks users                 |
| databricks_service_principals | The details of the Databricks service principals    |
| databricks_groups             | The details of the Databricks groups                |
| databricks_groups_membership  | The Databricks IDs for the groups and their members |
