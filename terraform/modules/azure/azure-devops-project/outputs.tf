output "id" {
  description = "The ID of the Azure DevOps project."
  value = azuredevops_project.this.id
}

output "name" {
  description = "The name of the Azure DevOps project."
  value = azuredevops_project.this.name
}

output "service_endpoints" {
  description = "The IDs of the service endpoints."
  sensitive = true
  value = {
  for endpoint in try(coalescelist(flatten([
    azuredevops_serviceendpoint_github.endpoints,
    azuredevops_serviceendpoint_azurerm.endpoints])), []) :
  endpoint.service_endpoint_name => endpoint.id
  }
}
