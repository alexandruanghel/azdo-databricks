## Description

Creates an Azure Virtual Network for [Databricks VNet injection](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-inject).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | The name of the Resource Group in which the resources should exist | `string` | n/a | yes |
| azure_location | Azure location in which the resources should exist | `string` | `null` | no |
| virtual_network_name | The name of the Virtual Network | `string` | `workers-vnet` | no |
| virtual_network_cidr | CIDR range for the Virtual Network | `string` | `10.179.0.0/16` | no |
| private_subnet_name | The name of the Private Subnet within the Virtual Network | `string` | `private-subnet` | no |
| private_subnet_cidr | CIDR range for the Private Subnet | `string` | `10.179.0.0/18` | no |
| public_subnet_name | The name of the Public Subnet within the Virtual Network | `string` | `public-subnet` | no |
| public_subnet_cidr | CIDR range for the Public Subnet | `string` | `10.179.64.0/18` | no |
| network_security_group_name | The name of the Databricks Network Security Group attached to the subnets | `string` | `databricks-nsg` | no |
| use_nat_gateway | Set true to deploy a NAT gateway for no public ip subnets | `bool` | `false` | no |
| nat_gateway_name | The name of the NAT gateway to be attached to the subnets | `string` | `databricks-nat-gateway` | no |
| nat_gateway_public_ip_name | The name of the NAT gateway public IP | `string` | `databricks-nat-public-ip` | no |
| service_endpoints | A list of service endpoints to associate with the public subnet | `list(string)` | `[]` | no |
| tags | A mapping of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| virtual_network_id | The ID of the Virtual Network |
| virtual_network_name | The name of the Virtual Network |
| private_subnet_id | The ID of the Private Subnet within the Virtual Network |
| private_subnet_name | The name of the Private Subnet within the Virtual Network |
| public_subnet_id | The ID of the Public Subnet within the Virtual Network |
| public_subnet_name | The name of the Public Subnet within the Virtual Network |
| network_security_group_id | The ID of the Databricks Network Security Group attached to the subnets |
| nat_gateway_id | The ID of the NAT gateway attached to the subnets |
| nat_public_ip_id | The ID of the NAT gateway public IP |
