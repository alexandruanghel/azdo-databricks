/**
* Tests for the azure-devops-pipeline module
*/
provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 1.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# Create a random string for test uniqueness
resource "random_string" "suffix" {
  length  = 10
  numeric = true
  lower   = true
  upper   = false
  special = false
}

# Set the rest of the test variables using the random string
locals {
  pipeline_defaults       = "tftest-pipeline-default-${random_string.suffix.result}"
  pipeline_with_variables = "tftest-pipeline-variables-${random_string.suffix.result}"
  project_name            = "tftest-project-pipelines-${random_string.suffix.result}"
  github_endpoint         = "tftest-endpoint-git-${random_string.suffix.result}"
}

# Build an Azure DevOps project with a GitHub Service connection
module "project_with_github_endpoint" {
  source           = "../../../modules/azure/azure-devops-project"
  project_name     = local.project_name
  github_endpoints = [local.github_endpoint]
#  github_pat       = random_string.suffix.result
}

# Build an Azure DevOps pipeline with default parameters
module "test_pipeline_defaults" {
  source             = "../../../modules/azure/azure-devops-pipeline"
  pipeline_name      = local.pipeline_defaults
  pipeline_path      = "azure-pipelines.yml"
  project_id         = module.project_with_github_endpoint.id
  github_endpoint_id = module.project_with_github_endpoint.service_endpoints[local.github_endpoint]
  github_repo_url    = "https://github.com/alexandruanghel/azdo-databricks"
}

# Build an Azure DevOps pipeline with two variables
module "test_pipeline_with_variables" {
  source             = "../../../modules/azure/azure-devops-pipeline"
  pipeline_name      = local.pipeline_with_variables
  pipeline_path      = "azure-pipelines.yml"
  project_id         = module.project_with_github_endpoint.id
  github_endpoint_id = module.project_with_github_endpoint.service_endpoints[local.github_endpoint]
  github_repo_url    = "https://github.com/alexandruanghel/azdo-databricks"
  github_branch      = "master"
  pipeline_variables = {
    tftest_var1 = "TF Test 1"
    tftest_var2 = "TF Test 3"
  }
}

# Terraform output
output "azure_devops_pipeline_tests" {
  value = {
    test_pipeline_defaults = {
      id       = module.test_pipeline_defaults.id
      name     = module.test_pipeline_defaults.name
      path     = module.test_pipeline_defaults.path
      revision = module.test_pipeline_defaults.revision
    }
    test_pipeline_with_variables = {
      id       = module.test_pipeline_with_variables.id
      name     = module.test_pipeline_with_variables.name
      path     = module.test_pipeline_with_variables.path
      revision = module.test_pipeline_with_variables.revision
    }
  }
}
