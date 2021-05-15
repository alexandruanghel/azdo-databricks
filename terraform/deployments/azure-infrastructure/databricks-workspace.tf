### Databricks workspace

# Deploy a Virtual Network for Databricks
module "databricks_vnet" {
  source                      = "../../modules/azure/databricks-vnet"
  azure_location              = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  virtual_network_name        = var.DATABRICKS_VNET_NAME
  virtual_network_cidr        = var.DATABRICKS_VNET_CIDR
  network_security_group_name = var.DATABRICKS_NSG_NAME
  private_subnet_name         = var.DATABRICKS_PRIVATE_SUBNET_NAME
  private_subnet_cidr         = var.DATABRICKS_PRIVATE_SUBNET_CIDR
  public_subnet_name          = var.DATABRICKS_PUBLIC_SUBNET_NAME
  public_subnet_cidr          = var.DATABRICKS_PUBLIC_SUBNET_CIDR
  tags                        = var.deployment_tags
}

# Deploy the Databricks workspace with the custom VNet
module "databricks_workspace_vnet_injection" {
  source                      = "../../modules/azure/databricks-workspace"
  azure_location              = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  workspace_name              = var.DATABRICKS_WORKSPACE_NAME
  pricing_tier                = var.DATABRICKS_PRICING_TIER
  virtual_network_id          = module.databricks_vnet.virtual_network_id
  private_subnet_name         = module.databricks_vnet.private_subnet_name
  public_subnet_name          = module.databricks_vnet.public_subnet_name
  tags                        = var.deployment_tags
  depends_on                  = [module.databricks_vnet]
}


### Terraform output

output "databricks_workspace" {
  value = {
    id                        = module.databricks_workspace_vnet_injection.id
    url                       = module.databricks_workspace_vnet_injection.workspace_url
    managed_resource_group_id = module.databricks_workspace_vnet_injection.managed_resource_group_id
  }
}
