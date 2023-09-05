/**
* Builds the core infrastructure.
* The user executing this must be Owner on the Subscription and Global administrator on the AD Tenant.
*/
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

terraform {
  required_version = "~> 1.5.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}

data "azurerm_client_config" "current" {}


### Terraform variables

variable "AZURE_LOCATION" {}
variable "INFRA_SP_NAME" {}
variable "DATA_SP_NAME" {}
variable "PROJECT_GROUP_NAME" {}
variable "DATABRICKS_RESOURCE_GROUP_NAME" {}
variable "KEY_VAULT_NAME" {}
variable "SECRET_NAME" {}
variable "TF_RESOURCE_GROUP_NAME" {}
variable "TF_STORAGE_ACCOUNT_NAME" {}
variable "TF_CONTAINER_NAME" { default = "tfstate" }
variable "AZURE_DEVOPS_PROJECT_NAME" {}
variable "AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME" {}
variable "AZURE_DEVOPS_DATA_ARM_ENDPOINT_NAME" {}
variable "AZURE_DEVOPS_GITHUB_ENDPOINT_NAME" {}
variable "AZURE_DEVOPS_GITHUB_REPO_URL" {}
variable "AZURE_DEVOPS_GITHUB_BRANCH" {}
variable "AZURE_DEVOPS_INFRA_PIPELINE_NAME" {}
variable "AZURE_DEVOPS_INFRA_PIPELINE_PATH" {}
variable "AZURE_DEVOPS_DATA_PIPELINE_NAME" {}
variable "AZURE_DEVOPS_DATA_PIPELINE_PATH" {}


### Azure core infrastructure

# Make sure all of the required Resource Provider are registered in the Subscription
# The Azure Provider mentions it will automatically register all of the Resource Providers but that's not the case for Microsoft.DataFactory"
resource "null_resource" "azure_resource_providers" {
  for_each = toset([
    "Microsoft.Compute",
    "Microsoft.Storage",
    "Microsoft.DataLakeStore",
    "Microsoft.Network",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
    "Microsoft.Databricks",
    "Microsoft.DataFactory",
    "Microsoft.DBforMySQL",
    "Microsoft.Sql"
  ])
  provisioner "local-exec" {
    command = "az provider register --namespace ${each.key} --wait"
  }
}

# Create the Azure Service Principal to be used for infrastructure deployment
module "infra_service_principal" {
  source            = "../../terraform/modules/azure/service-principal"
  name              = var.INFRA_SP_NAME
  api_permissions   = ["User.Read.All", "GroupMember.Read.All", "Application.Read.All"]
  secret_expiration = "17520h"
}

# Create the Azure Service Principal to be used by the data pipeline
module "data_service_principal" {
  source            = "../../terraform/modules/azure/service-principal"
  name              = var.DATA_SP_NAME
  secret_expiration = "17520h"
}

# Create the Azure Project group
resource "azuread_group" "project_group" {
  display_name            = var.PROJECT_GROUP_NAME
  prevent_duplicate_names = true
  security_enabled        = true
}

# Create the Databricks resource group
module "databricks_resource_group" {
  source              = "../../terraform/modules/azure/resource-group"
  azure_location      = var.AZURE_LOCATION
  resource_group_name = var.DATABRICKS_RESOURCE_GROUP_NAME
  owners              = [module.infra_service_principal.object_id]
}

# Create the Azure Key Vault
module "azure_key_vault" {
  source              = "../../terraform/modules/azure/key-vault"
  resource_group_name = module.databricks_resource_group.name
  key_vault_name      = var.KEY_VAULT_NAME
  depends_on          = [module.databricks_resource_group]
}

# Add the data pipeline Service Principal secret to the Key Vault
resource "azurerm_key_vault_secret" "sp_client_secret" {
  name         = var.SECRET_NAME
  value        = module.data_service_principal.secret
  content_type = module.data_service_principal.application_id
  key_vault_id = module.azure_key_vault.id
  depends_on   = [module.data_service_principal, module.azure_key_vault]
}


### Azure infrastructure for Terraform

# Create the Terraform resource group
module "tf_resource_group" {
  source              = "../../terraform/modules/azure/resource-group"
  azure_location      = var.AZURE_LOCATION
  resource_group_name = var.TF_RESOURCE_GROUP_NAME
  owners              = [module.infra_service_principal.object_id]
}

# Create the Terraform storage account (including the container)
module "tf_storage_account" {
  source               = "../../terraform/modules/azure/storage-account"
  azure_location       = module.tf_resource_group.location
  resource_group_name  = module.tf_resource_group.name
  storage_account_name = var.TF_STORAGE_ACCOUNT_NAME
  storage_containers   = [var.TF_CONTAINER_NAME]
  depends_on           = [module.tf_resource_group]
}

# Assign the "Storage Blob Data Contributor" Role on the Storage Account to the infra Service Principal
resource "azurerm_role_assignment" "tf_storage_account_data_contributor" {
  scope                = module.tf_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.infra_service_principal.object_id
}


### Azure DevOps Project

# Create the Azure DevOps project
# includes a GitHub type service endpoint
# includes an Azure RM type service endpoint to be used by the infra pipeline
# includes an Azure RM type service endpoint to be used by the data pipeline
module "azure_devops_project" {
  source           = "../../terraform/modules/azure/azure-devops-project"
  project_name     = var.AZURE_DEVOPS_PROJECT_NAME
  github_endpoints = [var.AZURE_DEVOPS_GITHUB_ENDPOINT_NAME]
  arm_endpoints    = [
    {
      name          = var.AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME
      client_id     = module.infra_service_principal.application_id
      client_secret = module.infra_service_principal.secret
    }, {
      name          = var.AZURE_DEVOPS_DATA_ARM_ENDPOINT_NAME
      client_id     = module.data_service_principal.application_id
      client_secret = module.data_service_principal.secret
    }
  ]
}

# Create the Azure Pipeline for infrastructure deployment
module "azure_devops_infra_pipeline" {
  source             = "../../terraform/modules/azure/azure-devops-pipeline"
  pipeline_name      = var.AZURE_DEVOPS_INFRA_PIPELINE_NAME
  pipeline_path      = var.AZURE_DEVOPS_INFRA_PIPELINE_PATH
  project_id         = module.azure_devops_project.id
  github_endpoint_id = module.azure_devops_project.service_endpoints[var.AZURE_DEVOPS_GITHUB_ENDPOINT_NAME]
  github_repo_url    = var.AZURE_DEVOPS_GITHUB_REPO_URL
  github_branch      = var.AZURE_DEVOPS_GITHUB_BRANCH
  pipeline_variables = {
    serviceConnection                   = var.AZURE_DEVOPS_INFRA_ARM_ENDPOINT_NAME
    provisionedServicePrincipalClientId = module.data_service_principal.application_id
    provisionedProjectGroupName         = azuread_group.project_group.display_name
    provisionedResourceGroupName        = module.databricks_resource_group.name
    provisionedKeyVaultName             = module.azure_key_vault.name
    provisionedSecretName               = var.SECRET_NAME
    tfResourceGroupName                 = var.TF_RESOURCE_GROUP_NAME
    tfStorageAccountName                = var.TF_STORAGE_ACCOUNT_NAME
    tfContainerName                     = var.TF_CONTAINER_NAME
  }
  depends_on = [module.azure_devops_project]
}

# Create the Azure Pipeline for the Azure Data Factory data pipeline
module "azure_devops_data_pipeline" {
  source             = "../../terraform/modules/azure/azure-devops-pipeline"
  pipeline_name      = var.AZURE_DEVOPS_DATA_PIPELINE_NAME
  pipeline_path      = var.AZURE_DEVOPS_DATA_PIPELINE_PATH
  project_id         = module.azure_devops_project.id
  github_endpoint_id = module.azure_devops_project.service_endpoints[var.AZURE_DEVOPS_GITHUB_ENDPOINT_NAME]
  github_repo_url    = var.AZURE_DEVOPS_GITHUB_REPO_URL
  github_branch      = var.AZURE_DEVOPS_GITHUB_BRANCH
  pipeline_variables = {
    serviceConnection            = var.AZURE_DEVOPS_DATA_ARM_ENDPOINT_NAME
    provisionedResourceGroupName = module.databricks_resource_group.name
    provisionedKeyVaultName      = module.azure_key_vault.name
    provisionedSecretName        = var.SECRET_NAME
  }
  depends_on = [module.azure_devops_project]
}

# Install the Terraform extension for Azure DevOps
resource "null_resource" "azure_devops_terraform_extension" {
  provisioner "local-exec" {
    command = "/bin/bash ${path.module}/../../scripts/azdo_extension.sh install 'custom-terraform-tasks' 'ms-devlabs'"
  }
}


### Terraform output

output "terraform_resources" {
  value = {
    resource_group_id                = module.tf_resource_group.id
    resource_group_name              = module.tf_resource_group.name
    terraform_storage_account_id     = module.tf_storage_account.id
    terraform_storage_account_name   = module.tf_storage_account.name
    terraform_storage_container_name = var.TF_CONTAINER_NAME
  }
}

output "databricks_resources" {
  value = {
    resource_group_id                      = module.databricks_resource_group.id
    resource_group_name                    = module.databricks_resource_group.name
    key_vault_id                           = module.azure_key_vault.id
    key_vault_name                         = module.azure_key_vault.name
    secret_name                            = azurerm_key_vault_secret.sp_client_secret.name
    infra_service_principal_application_id = module.infra_service_principal.application_id
    infra_service_principal_object_id      = module.infra_service_principal.object_id
    data_service_principal_application_id  = module.data_service_principal.application_id
    data_service_principal_object_id       = module.data_service_principal.object_id
    project_group_name                     = azuread_group.project_group.display_name
    project_group_object_id                = azuread_group.project_group.object_id
  }
}

output "azure_devops_resources" {
  value = {
    project_name        = var.AZURE_DEVOPS_PROJECT_NAME
    infra_pipeline_name = var.AZURE_DEVOPS_INFRA_PIPELINE_NAME
    infra_pipeline_path = module.azure_devops_infra_pipeline.path
    data_pipeline_name  = var.AZURE_DEVOPS_DATA_PIPELINE_NAME
    data_pipeline_path  = module.azure_devops_data_pipeline.path
  }
}
