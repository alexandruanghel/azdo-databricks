/**
* Builds the Azure infrastructure for the data pipeline and project.
*/

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
  skip_provider_registration = true
}

terraform {
  required_version = "~> 1.5.7"

  backend "azurerm" {}

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}


### Data Sources

# Get information about the AzureRM provider
data "azurerm_client_config" "current" {}

# Get information about the pre-provisioned Service Principal
data "azuread_service_principal" "data_service_principal" {
  application_id = var.DATA_SERVICE_PRINCIPAL_CLIENT_ID
}

# Get information about the pre-provisioned Project group
data "azuread_group" "project_group" {
  display_name     = var.PROJECT_GROUP_NAME
  security_enabled = true
}

# Get information about the pre-provisioned Resource Group
data "azurerm_resource_group" "main" {
  name = var.RESOURCE_GROUP_NAME
}

# Get information about the pre-provisioned Key Vault
data "azurerm_key_vault" "main" {
  name                = var.KEY_VAULT_NAME
  resource_group_name = var.RESOURCE_GROUP_NAME
}
