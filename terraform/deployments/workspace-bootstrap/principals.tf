### Databricks Principals

# Add the Azure Data Factory Service Principal to the Databricks workspace
# The Service Principal must have 'allow_cluster_create' in order to create new jobs clusters as policies are not supported by ADF
resource "databricks_service_principal" "data_factory" {
  application_id           = data.azuread_service_principal.data_factory.application_id
  display_name             = data.azuread_service_principal.data_factory.display_name
  external_id              = data.azuread_service_principal.data_factory.object_id
  workspace_access         = true
  databricks_sql_access    = true
  allow_cluster_create     = true
  active                   = true
  force                    = true
  disable_as_user_deletion = true
}

# Add the data pipeline Service Principal to the Databricks workspace
resource "databricks_service_principal" "data_pipeline" {
  application_id           = data.azuread_service_principal.data_pipeline.application_id
  display_name             = data.azuread_service_principal.data_pipeline.display_name
  external_id              = data.azuread_service_principal.data_pipeline.object_id
  workspace_access         = true
  databricks_sql_access    = true
  allow_cluster_create     = true
  active                   = true
  force                    = true
  disable_as_user_deletion = true
}

# Sync the AD Project group with the Databricks workspace
module "project_group_sync" {
  source                = "../../modules/databricks/azure-groups-sync"
  groups                = [var.PROJECT_GROUP_NAME]
  workspace_access      = [var.PROJECT_GROUP_NAME]
  databricks_sql_access = [var.PROJECT_GROUP_NAME]
}

# Terraform output
output "databricks_principals" {
  value = {
    data_factory = {
      id           = databricks_service_principal.data_factory.id
      display_name = data.azuread_service_principal.data_factory.display_name
    }
    data_pipeline = {
      id           = databricks_service_principal.data_pipeline.id
      display_name = data.azuread_service_principal.data_pipeline.display_name
    }
    project_group = module.project_group_sync.databricks_groups
  }
}
