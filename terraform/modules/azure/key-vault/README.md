## Description

Creates an Azure Key Vault.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | The name of the Resource Group in which the resources should exist | `string` | n/a | yes |
| azure_location | Azure location in which the resources should exist | `string` | `null` | no |
| key_vault_name | The name of the Azure Key Vault | `string` | n/a | yes |
| sku_name | The name of the SKU used for this Key Vault | `string` | `standard` | no |
| soft_delete_retention_days | The number of days that items should be retained for once soft-deleted | `number` | `7` | no |
| tags | A mapping of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Azure Key Vault |
| name | The name of the Azure Key Vault |
| uri | The URI of the Azure Key Vault |
| policy | The Azure Key Vault policy ID |
