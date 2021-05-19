output "virtual_network_id" {
  description = "The ID of the Virtual Network."
  value       = azurerm_virtual_network.core.id
}

output "virtual_network_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.core.name
}

output "private_subnet_id" {
  description = "The ID of the Private Subnet within the Virtual Network."
  value       = azurerm_subnet.databricks_private_subnet.id
}

output "private_subnet_name" {
  description = "The name of the Private Subnet within the Virtual Network."
  value       = azurerm_subnet.databricks_private_subnet.name
}

output "public_subnet_id" {
  description = "The ID of the Public Subnet within the Virtual Network."
  value       = azurerm_subnet.databricks_public_subnet.id
}

output "public_subnet_name" {
  description = "The name of the Public Subnet within the Virtual Network."
  value       = azurerm_subnet.databricks_public_subnet.name
}

output "network_security_group_id" {
  description = "The ID of the Databricks Network Security Group attached to the subnets."
  value       = azurerm_virtual_network.core.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT gateway attached to the subnets."
  value       = length(azurerm_nat_gateway.databricks) > 0 ? azurerm_nat_gateway.databricks[0].id : null

}

output "nat_public_ip_id" {
  description = "The ID of the NAT gateway public IP."
  value       = length(azurerm_public_ip.databricks) > 0 ? azurerm_public_ip.databricks[0].id : null
}
