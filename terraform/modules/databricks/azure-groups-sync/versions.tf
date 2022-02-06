terraform {
  required_version = "~> 1.1"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.17"
    }
    databricks = {
      source = "databrickslabs/databricks"
      version = ">= 0.4.8"
    }
  }
}
