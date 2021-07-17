terraform {
  required_version = "~> 1.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 1.6"
    }
    databricks = {
      source = "databrickslabs/databricks"
      version = ">= 0.3.5"
    }
  }
}
