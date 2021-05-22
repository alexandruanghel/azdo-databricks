/**
* Creates an Azure Service Principal with optional App Owners, API Permissions and secret.
*/
data "azurerm_client_config" "current" {}

# Use an external data source to get the API Permission ID (no data source exists for this yet in the azuread provider)
data "external" "ad_permission_id" {
  count    = length(var.api_permissions)
  program  = ["/bin/bash", "${path.module}/scripts/get_api_permission_id.sh"]
  query    = {
    graph_type     = "ad"
    api_permission = var.api_permissions[count.index]
  }
}

# Create the Azure App Registration
resource "azuread_application" "sp" {
  display_name    = var.name
  identifier_uris = ["http://${var.name}"]
  owners          = var.owners

  dynamic required_resource_access {
    for_each = length(var.api_permissions) > 0 ? [1] : []
    content {
      resource_app_id = "00000002-0000-0000-c000-000000000000"
      dynamic resource_access {
        for_each = data.external.ad_permission_id
        content {
          id   = resource_access.value.result.api_permission_id
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

# Grant admin-consent using az cli (no resource exists for this yet in the azuread provider, see #230)
resource "null_resource" "admin_consent" {
  count    = length(var.api_permissions) > 0 ? 1 : 0
  triggers = {
    service_principal_api_permissions = lower(join(",", sort(var.api_permissions)))
    service_principal_id              = azuread_application.sp.application_id
  }

  provisioner "local-exec" {
    command = "az ad app permission admin-consent --id '${azuread_application.sp.application_id}'"
  }

  depends_on = [azuread_service_principal.sp]
}

# Generate a random password to be used for the App Registration Client Secret (if one was not provided)
resource "random_password" "sp" {
  count            = var.secret == null ? 1 : 0
  length           = 34
  special          = true
  override_special = "_~@."

  keepers = {
    service_principal = azuread_service_principal.sp.id
  }
}

# Create the Service Principal client secret
resource "azuread_application_password" "sp" {
  application_object_id = azuread_application.sp.id
  display_name          = "Managed by Terraform"
  value                 = var.secret == null ? random_password.sp[0].result : var.secret
  end_date_relative     = var.secret_expiration
  depends_on            = [azuread_service_principal.sp]
}
