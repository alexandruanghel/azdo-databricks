/**
* Creates an Azure Service Principal with optional App Owners and API Permissions (including admin-consent).
*/
data "azurerm_client_config" "current" {}

# Get the well-known application IDs for APIs published by Microsoft
data "azuread_application_published_app_ids" "well_known" {}

# Get all information about the Microsoft Graph API
data "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

# Create the Azure App Registration
resource "azuread_application" "sp" {
  display_name    = var.name
  identifier_uris = ["api://${var.name}"]
  owners          = var.owners

  # Use the app_role_ids mapping to get the app role IDs of the required API Permissions
  dynamic required_resource_access {
    for_each = length(var.api_permissions) > 0 ? [1] : []
    content {
      resource_app_id = data.azuread_service_principal.msgraph.application_id
      dynamic resource_access {
        for_each = var.api_permissions
        content {
          id   = data.azuread_service_principal.msgraph.app_role_ids[resource_access.value]
          type = "Role"
        }
      }
    }
  }

  web {
    homepage_url  = "https://${var.name}"
    redirect_uris = []

    implicit_grant {
      access_token_issuance_enabled = false
    }
  }
}

# Create the Service Principal associated with the App Registration
resource "azuread_service_principal" "sp" {
  application_id               = azuread_application.sp.application_id
  app_role_assignment_required = false
  depends_on                   = [azuread_application.sp]
}

# Grant admin-consent for the requested API Permissions
resource "azuread_app_role_assignment" "admin_consent" {
  for_each = toset(var.api_permissions)

  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids[each.value]
  principal_object_id = azuread_service_principal.sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Create the Service Principal client secret
resource "azuread_application_password" "sp" {
  application_object_id = azuread_application.sp.id
  display_name          = "Managed by Terraform"
  end_date_relative     = var.secret_expiration
  depends_on            = [azuread_service_principal.sp]
}
