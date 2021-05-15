### Databricks Folders and Notebooks

# Deploy Databricks generic notebooks in a Shared location
resource "databricks_notebook" "shared" {
  for_each = fileset(var.NOTEBOOKS_SHARED_SOURCE_LOCATION, "*")
  source   = "${var.NOTEBOOKS_SHARED_SOURCE_LOCATION}/${each.value}"
  path     = "${var.NOTEBOOKS_SHARED_WORKSPACE_FOLDER}/${replace(each.value, "/(\\..*)$/", "")}"
}

# Create an empty workspace folder for the Pipeline notebooks
module "pipeline_folder" {
  source      = "../../modules/databricks/empty-folder"
  folder_path = var.NOTEBOOKS_PIPELINE_WORKSPACE_FOLDER
  permissions = [{principal = data.azuread_service_principal.data_pipeline.application_id, type = "service_principal", permission = "CAN_MANAGE"},
                 {principal = data.azuread_service_principal.data_factory.application_id, type = "service_principal", permission = "CAN_RUN"}]
  depends_on  = [module.data_pipeline_databricks_principal, module.data_factory_databricks_principal]
}

# Create an empty workspace folder for the Project notebooks
module "project_folder" {
  source      = "../../modules/databricks/empty-folder"
  folder_path = var.NOTEBOOKS_PROJECT_WORKSPACE_FOLDER
  permissions = [{principal = var.PROJECT_GROUP_NAME, type = "group", permission = "CAN_MANAGE"}]
  depends_on  = [module.project_group_sync]
}

# Terraform output
output "databricks_folders" {
  value = {
    pipeline_folder = module.pipeline_folder.details
    project_folder  = module.project_folder.details
    shared_folder   = {
      path               = var.NOTEBOOKS_SHARED_WORKSPACE_FOLDER
      notebook_path_list = toset([for path, details in databricks_notebook.shared : details])
    }
  }
}
