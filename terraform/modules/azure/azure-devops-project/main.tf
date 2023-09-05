/**
* Creates an Azure DevOps project with optional service endpoints (AzureRM or GitHub).
*/
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" { subscription_id = data.azurerm_client_config.current.subscription_id }

resource "azuredevops_project" "this" {
  name               = var.project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

resource "azuredevops_serviceendpoint_github" "endpoints" {
  count                 = length(var.github_endpoints)
  project_id            = azuredevops_project.this.id
  service_endpoint_name = var.github_endpoints[count.index]

  auth_personal {
    # Also can be set with AZDO_GITHUB_SERVICE_CONNECTION_PAT environment variable
    personal_access_token = var.github_pat
  }
}

resource "azuredevops_serviceendpoint_azurerm" "endpoints" {
  count                 = length(var.arm_endpoints)
  project_id            = azuredevops_project.this.id
  service_endpoint_name = var.arm_endpoints[count.index].name
  credentials {
    serviceprincipalid  = var.arm_endpoints[count.index].client_id
    serviceprincipalkey = var.arm_endpoints[count.index].client_secret
  }
  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

resource "azuredevops_pipeline_authorization" "enable_for_all" {
  count       = length(var.arm_endpoints)
  project_id  = azuredevops_project.this.id
  resource_id = azuredevops_serviceendpoint_azurerm.endpoints[count.index].id
  type        = "endpoint"
}
