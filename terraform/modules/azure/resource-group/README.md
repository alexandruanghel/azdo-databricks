## Description

Creates an Azure Resource Group with optional IAM roles attached to it.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | The name of the Resource Group | `string` | n/a | yes |
| azure_location | Azure location for the Resource Group | `string` | n/a | yes |
| owners | A list of Object IDs that should have the Owner role over the Resource Group | `list(string)` | `[]` | no |
| contributors | A list of Object IDs that should have the Contributor role over the Resource Group | `list(string)` | `[]` | no |
| readers | A list of Object IDs that should have the Reader role over the Resource Group | `list(string)` | `[]` | no |
| tags | A mapping of tags to assign to the Resource Group | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Resource Group |
| name | The name of the Resource Group |
| location | The location of the Resource Group |
