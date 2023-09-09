terraform {
  required_version = "~> 1.5.7"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.41"
    }
    databricks = {
      source = "databricks/databricks"
      version = ">= 1.24.1"
    }
  }
}
