/**
* Creates an Azure DevOps pipeline (hosted on GitHub) with optional variables.
*/
resource "azuredevops_build_definition" "pipeline" {
  project_id = var.project_id
  name       = var.pipeline_name

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = regex("^https://[w.]*github.com/(?P<repo_id>[^/?#]+/[^/?#]+)", var.github_repo_url)["repo_id"]
    branch_name           = var.github_branch
    yml_path              = var.pipeline_path
    service_connection_id = var.github_endpoint_id
  }

  dynamic "variable" {
    for_each = var.pipeline_variables
    content {
      name  = variable.key
      value = variable.value
    }
  }
}
