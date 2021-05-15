/**
* Creates an empty folder in the Databricks workspace (with optional permissions).
*/

# Create an empty notebook in order to create the folder path
resource "databricks_notebook" "empty" {
  path           = "${var.folder_path}/empty"
  content_base64 = base64encode("#")
  language       = "PYTHON"
}

# Get the folder path ID to use it for permissions
data "databricks_notebook_paths" "folder" {
  path       = var.folder_path
  recursive  = false
  depends_on = [databricks_notebook.empty]
}

# Assign permissions to the folder
resource "databricks_permissions" "folder" {
  count          = length(var.permissions) > 0 ? 1 : 0
  directory_path = data.databricks_notebook_paths.folder.path

  dynamic "access_control" {
    for_each = toset(var.permissions)
    content {
      user_name              = access_control.value.type == "user" ? access_control.value.principal : ""
      group_name             = access_control.value.type == "group" ? access_control.value.principal : ""
      service_principal_name = access_control.value.type == "service_principal" ? access_control.value.principal : ""
      permission_level       = access_control.value.permission
    }
  }
}
