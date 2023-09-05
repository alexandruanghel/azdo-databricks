/**
* Bootstraps the Databricks workspace for the data pipeline and project.
*/

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

terraform {
  required_version = "~> 1.5.6"

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
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.24"
    }
  }
}


### Data Sources

# Get information about the AzureRM provider
data "azurerm_client_config" "current" {}

# Get information about the pre-provisioned Resource Group
data "azurerm_resource_group" "main" {
  name = var.RESOURCE_GROUP_NAME
}

# Get information about the pre-provisioned Project group
data "azuread_group" "project_group" {
  display_name     = var.PROJECT_GROUP_NAME
  security_enabled = true
}

# Get information about the pre-provisioned Service Principal
data "azuread_service_principal" "data_pipeline" {
  application_id = var.DATA_SERVICE_PRINCIPAL_CLIENT_ID
}

# Get information about the Azure Key Vault
data "azurerm_key_vault" "main" {
  name                = var.KEY_VAULT_NAME
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get information about the Databricks workspace
data "azurerm_databricks_workspace" "main" {
  name                = var.DATABRICKS_WORKSPACE_NAME
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get information about the Azure Data Factory
data "azurerm_data_factory" "main" {
  name                = var.DATA_FACTORY_NAME
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get the Azure Data Factory Service Principal ID of the Managed Identity Object ID
data "azuread_service_principal" "data_factory" {
  object_id = data.azurerm_data_factory.main.identity[0].principal_id
}

# Configure the Databricks Terraform provider
provider "databricks" {
  host = data.azurerm_databricks_workspace.main.workspace_url
}
