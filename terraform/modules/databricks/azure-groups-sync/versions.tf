terraform {
  required_version = "~> 1.4"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.36"
    }
    databricks = {
      source = "databricks/databricks"
      version = ">= 1.12"
    }
  }
}
