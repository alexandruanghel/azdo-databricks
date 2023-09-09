## Description

Creates an Azure Data Factory with optional Key Vault linked services.

## Inputs

| Name                | Description                                                           | Type           | Default | Required |
|---------------------|-----------------------------------------------------------------------|----------------|---------|:--------:|
| resource_group_name | The name of the Resource Group in which the resources should exist    | `string`       | n/a     |   yes    |
| azure_location      | Azure location in which the resources should exist                    | `string`       | `null`  |    no    |
| data_factory_name   | The name of the Azure Data Factory                                    | `string`       | n/a     |   yes    |
| key_vault_ids       | A list of Azure Key Vault IDs to be used for creating linked services | `list(string)` | `[]`    |    no    |
| tags                | A mapping of tags to assign to the resources                          | `map(string)`  | `{}`    |    no    |

## Outputs

| Name                      | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| id                        | The ID of the Azure Data Factory                                            |
| name                      | The name of the Azure Data Factory                                          |
| principal_id              | The ID of the Azure Data Factory Managed Identity in Azure Active Directory |
| key_vault_linked_services | Details of the Azure Data Factory linked Key Vault services                 |
