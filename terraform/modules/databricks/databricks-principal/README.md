## Description

Adds a principal (user, group or service_principal) to the Databricks workspace with an optional group membership.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| principal_identifier | The identifier of the principal (user name, service principal id or group name) | `string` | n/a | yes |
| principal_type | The type of the principal (`user`, `group` or `service_principal`) | `string` | n/a | yes |
| display_name | The display name of the principal | `string` | `""` | no |
| allow_cluster_create | Allows the principal to have cluster create privileges | `bool` | `false` | no |
| allow_instance_pool_create | Allows the principal to have instance pool create privileges | `bool` | `false` | no |
| groups | A list of groups this principal should be member of | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the principal in the Databricks workspace |
| details | The Databricks details of the principal in the Databricks workspace |
| membership | List of groups this principal belongs to |
