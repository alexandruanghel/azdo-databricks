### Azure infrastructure

# Deploy the Azure Data Lake Gen 2 Storage Account
module "data_lake_gen_2" {
  source                 = "../../modules/azure/storage-account"
  azure_location         = data.azurerm_resource_group.main.location
  resource_group_name    = data.azurerm_resource_group.main.name
  storage_account_name   = var.STORAGE_ACCOUNT_NAME
  hierarchical_namespace = true
  storage_containers     = [var.PIPELINE_CONTAINER_NAME, var.PROJECT_CONTAINER_NAME]
  allowed_subnet_ids     = [module.databricks_vnet.public_subnet_id]
  network_default_action = "Allow"
  tags                   = var.deployment_tags
  depends_on             = [module.databricks_vnet]
}

# Assign the "Storage Blob Data Contributor" Role on the Storage Account to the data pipeline Service Principal
resource "azurerm_role_assignment" "data_service_principal_storage_data_contributor" {
  scope                = module.data_lake_gen_2.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.data_service_principal.object_id
  depends_on           = [module.data_lake_gen_2]
}

# Assign the "Storage Blob Data Reader" Role on the Storage Account to the Project group
resource "azurerm_role_assignment" "project_group_storage_data_reader" {
  scope                = module.data_lake_gen_2.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azuread_group.project_group.object_id
  depends_on           = [module.data_lake_gen_2]
}

# Add the AzureRM provider principal to the Key Vault Access policies with 'list get set' permissions on secrets
resource "azurerm_key_vault_access_policy" "infra_sp" {
  key_vault_id       = data.azurerm_key_vault.main.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["get", "list", "set"]
}

# Add the data pipeline Service Principal to the Key Vault Access policies with 'list get set' permissions on secrets
resource "azurerm_key_vault_access_policy" "data_sp" {
  key_vault_id       = data.azurerm_key_vault.main.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azuread_service_principal.data_service_principal.object_id
  secret_permissions = ["get", "list", "set"]
}

# Deploy the Azure Data Factory with a Key Vault linked service
module "data_factory_with_key_vault" {
  source              = "../../modules/azure/data-factory"
  azure_location      = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  data_factory_name   = var.DATA_FACTORY_NAME
  key_vault_ids       = [data.azurerm_key_vault.main.id]
  tags                = var.deployment_tags
}

# Add the Azure Data Factory System Identity to the Key Vault Access policies with 'list get' permissions on secrets
resource "azurerm_key_vault_access_policy" "data_factory_sp" {
  key_vault_id       = data.azurerm_key_vault.main.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = module.data_factory_with_key_vault.principal_id
  secret_permissions = ["get", "list"]
}

# Assign the "Reader" Role on the Resource Group to the data pipeline Service Principal
resource "azurerm_role_assignment" "data_service_principal_rg_reader" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_service_principal.data_service_principal.object_id
}

# Assign the "Reader" Role on the Resource Group to the Project group
resource "azurerm_role_assignment" "project_group_rg_reader" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_group.project_group.object_id
}

# Assign the "Data Factory Contributor" Role on the Resource Group to the data pipeline Service Principal
resource "azurerm_role_assignment" "data_service_principal_adf_contributor" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = data.azuread_service_principal.data_service_principal.object_id
}

# Assign the "Data Factory Contributor" Role on the Resource Group to the Project group
resource "azurerm_role_assignment" "project_group_adf_contributor" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = data.azuread_group.project_group.object_id
}


### Terraform output

output "azure_infrastructure" {
  value = {
    resource_group_id                     = data.azurerm_resource_group.main.id
    project_group_object_id               = data.azuread_group.project_group.object_id
    data_service_principal_object_id      = data.azuread_service_principal.data_service_principal.object_id
    data_lake_storage_account_id          = module.data_lake_gen_2.id
    key_vault_id                          = data.azurerm_key_vault.main.id
    data_factory_id                       = module.data_factory_with_key_vault.id
    data_factory_principal_id             = module.data_factory_with_key_vault.principal_id
    data_factory_key_vault_linked_service = module.data_factory_with_key_vault.key_vault_linked_services[0].name
  }
}
