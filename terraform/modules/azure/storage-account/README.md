## Description

Creates an Azure Storage Account (either Blob or ADLS) with optional parameters.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | The name of the Resource Group in which the resources should exist | `string` | n/a | yes |
| azure_location | Azure location in which the resources should exist | `string` | `null` | no |
| storage_account_name | The name of the Storage Account | `string` | n/a | yes |
| hierarchical_namespace | Set to true for an Azure Data Lake Gen 2 Storage Account | `bool` | `false` | no |
| storage_containers | A list of containers to be created within the Storage Account | `list(string)` | `["default"]` | no |
| account_replication_type | The type of replication to use for the Storage Account | `string` | `LRS` | no |
| allowed_subnet_ids | The virtual network subnet IDs allowed to connect to the Storage Account | `list(string)` | `[]` | no |
| allowed_ips | The IPs allowed to connect to the Storage Account | `list(string)` | `[]` | no |
| network_default_action | Specifies the default action of allow or deny when no other rules match | `string` | `Allow` | no |
| tags | A mapping of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Storage Account |
| name | The name of the Storage Account |
