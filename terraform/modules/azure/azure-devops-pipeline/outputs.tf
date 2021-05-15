output "id" {
  description = "The ID of the Azure DevOps pipeline definition."
  value       = azuredevops_build_definition.pipeline.id
}

output "name" {
  description = "The name of the Azure DevOps pipeline definition."
  value       = azuredevops_build_definition.pipeline.name
}

output "path" {
  description = "The path of the Azure DevOps pipeline definition in the repository."
  value       = join("/", [var.github_repo_url, var.pipeline_path])
}

output "revision" {
  description = "The revision of the Azure DevOps pipeline definition."
  value       = azuredevops_build_definition.pipeline.revision
}
