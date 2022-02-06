## Description

Creates an Azure Service Principal with optional App Owners and API Permissions (including admin-consent).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The display name for the App Registration | `string` | n/a | yes |
| owners | A list of Azure AD Object IDs that will be granted ownership of the application | `list(string)` | `[]` | no |
| api_permissions | A list of API Permissions that should be assigned to this App (including admin consent) | `list(string)` | `[]` | no |
| secret_expiration | A relative duration for which the Password is valid | `string` | `8760h` | no |

## Outputs

| Name | Description |
|------|-------------|
| object_id | The AD Object ID of the Service Principal |
| application_id | The Application ID (Client ID) of the Service Principal |
| secret | The Password / Secret (Client Secret) of the Service Principal |
