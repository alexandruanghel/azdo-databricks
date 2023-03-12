### Databricks Folders and Notebooks

# Deploy Databricks generic notebooks in a Shared location
resource "databricks_notebook" "shared" {
  for_each = fileset(var.NOTEBOOKS_SHARED_SOURCE_LOCATION, "*")
  source   = "${var.NOTEBOOKS_SHARED_SOURCE_LOCATION}/${each.value}"
  path     = "${var.NOTEBOOKS_SHARED_WORKSPACE_FOLDER}/${replace(each.value, "/(\\..*)$/", "")}"
}

# Create an empty workspace folder for the Pipeline notebooks
resource "databricks_directory" "pipeline_folder" {
  path = var.NOTEBOOKS_PIPELINE_WORKSPACE_FOLDER
}

resource "databricks_permissions" "pipeline_folder" {
  directory_path = databricks_directory.pipeline_folder.path

  access_control {
    service_principal_name = data.azuread_service_principal.data_pipeline.application_id
    permission_level       = "CAN_MANAGE"
  }

  access_control {
    service_principal_name = data.azuread_service_principal.data_factory.application_id
    permission_level       = "CAN_RUN"
  }

  depends_on     = [databricks_directory.pipeline_folder, module.data_factory_databricks_principal, module.data_pipeline_databricks_principal]
}

# Create an empty workspace folder for the Project notebooks
resource "databricks_directory" "project_folder" {
  path = var.NOTEBOOKS_PROJECT_WORKSPACE_FOLDER
}

resource "databricks_permissions" "project_folder" {
  directory_path = databricks_directory.project_folder.path

  access_control {
    group_name       = var.PROJECT_GROUP_NAME
    permission_level = "CAN_MANAGE"
  }

  depends_on     = [databricks_directory.project_folder, module.project_group_sync]
}

# Terraform output
output "databricks_folders" {
  value = {
    pipeline_folder = databricks_directory.pipeline_folder.path
    project_folder  = databricks_directory.project_folder.path
    shared_folder   = {
      path               = var.NOTEBOOKS_SHARED_WORKSPACE_FOLDER
      notebook_path_list = toset([for path, details in databricks_notebook.shared : details])
    }
  }
}
