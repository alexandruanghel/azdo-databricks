## Description

Creates an empty folder in the Databricks workspace (with optional permissions).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| folder_path | The workspace path to the folder | `string` | n/a | yes |
| permissions | An object of permissions to be assigned to the folder | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The path of the folder in the Databricks workspace |
| details | Details about the folder |
| membership | List with the folder permissions |
