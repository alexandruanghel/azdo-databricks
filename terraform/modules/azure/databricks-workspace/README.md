## Description

Creates an Azure Databricks workspace with
optional [VNet injection](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-inject).

## Inputs

| Name                                                 | Description                                                                                                                             | Type          | Default          | Required |
|------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|---------------|------------------|:--------:|
| resource_group_name                                  | The name of the Resource Group in which the resources should exist                                                                      | `string`      | n/a              |   yes    |
| azure_location                                       | Azure location in which the resources should exist                                                                                      | `string`      | `null`           |    no    |
| workspace_name                                       | The name of the Databricks workspace resource                                                                                           | `string`      | n/a              |   yes    |
| managed_resource_group_name                          | The name of the Resource Group where Azure should place the managed Databricks resources                                                | `string`      | `null`           |    no    |
| pricing_tier                                         | The pricing tier to use for the Databricks workspace                                                                                    | `string`      | `premium`        |    no    |
| virtual_network_id                                   | The Azure Resource ID of the Virtual Network for VNet injection                                                                         | `string`      | `null`           |    no    |
| private_subnet_name                                  | The name of the Private Subnet within the Virtual Network                                                                               | `string`      | `private-subnet` |    no    |
| private_subnet_network_security_group_association_id | The resource ID of the azurerm_subnet_network_security_group_association resource which is referred to by the private_subnet_name field | `string`      | `null`           |    no    |
| public_subnet_name                                   | The name of the Public Subnet within the Virtual Network                                                                                | `string`      | `public-subnet`  |    no    |
| public_subnet_network_security_group_association_id  | The resource ID of the azurerm_subnet_network_security_group_association resource which is referred to by the public_subnet_name field  | `string`      | `null`           |    no    |
| tags                                                 | A mapping of tags to assign to the resources                                                                                            | `map(string)` | `{}`             |    no    |

## Outputs

| Name                        | Description                                                                   |
|-----------------------------|-------------------------------------------------------------------------------|
| id                          | The Azure Resource ID of the Databricks workspace                             |
| workspace_name              | The name of the Databricks workspace                                          |
| workspace_id                | The unique identifier of the Databricks workspace in Databricks control plane |
| workspace_url               | The workspace URL                                                             |
| managed_resource_group_name | The name of the Managed Resource Group for managed Databricks resources       |
| managed_resource_group_id   | The Azure Resource ID of the Managed Resource Group                           |
