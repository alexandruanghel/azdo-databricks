/**
* Bootstraps the Databricks workspace for the data pipeline and project.
*/

provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 0.14"

  backend "azurerm" {}

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 1.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.58"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    databricks = {
      source  = "databrickslabs/databricks"
      version = "~> 0.3"
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
  azure_workspace_resource_id = data.azurerm_databricks_workspace.main.id
}
