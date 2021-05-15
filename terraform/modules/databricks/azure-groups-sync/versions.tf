terraform {
  required_version = "~> 0.14"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 1.4"
    }
    databricks = {
      source = "databrickslabs/databricks"
      version = ">= 0.3.2"
    }
  }
}
