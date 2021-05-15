### Databricks Principals

# Add the Azure Data Factory Service Principal to the Databricks workspace
# The Service Principal must have 'allow_cluster_create' in order to create new jobs clusters as policies are not supported by ADF
module "data_factory_databricks_principal" {
  source                     = "../../modules/databricks/databricks-principal"
  principal_type             = "service_principal"
  principal_identifier       = data.azuread_service_principal.data_factory.application_id
  display_name               = data.azuread_service_principal.data_factory.display_name
  allow_cluster_create       = true
  allow_instance_pool_create = false
}

# Add the data pipeline Service Principal to the Databricks workspace
module "data_pipeline_databricks_principal" {
  source                     = "../../modules/databricks/databricks-principal"
  principal_type             = "service_principal"
  principal_identifier       = data.azuread_service_principal.data_pipeline.application_id
  display_name               = data.azuread_service_principal.data_pipeline.display_name
  allow_cluster_create       = true
  allow_instance_pool_create = false
}

# Sync the AD Project group with the Databricks workspace
module "project_group_sync" {
  source = "../../modules/databricks/azure-groups-sync"
  groups = [var.PROJECT_GROUP_NAME]
}

# Terraform output
output "databricks_principals" {
  value = {
    data_factory = {
      id           = module.data_factory_databricks_principal.id
      display_name = data.azuread_service_principal.data_factory.display_name
    }
    data_pipeline = {
      id           = module.data_pipeline_databricks_principal.id
      display_name = data.azuread_service_principal.data_pipeline.display_name
    }
    project_group = module.project_group_sync.databricks_groups[0]
  }
}
