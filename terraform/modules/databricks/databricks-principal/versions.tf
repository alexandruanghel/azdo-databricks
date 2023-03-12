terraform {
  required_version = "~> 1.4"

  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = ">= 1.12"
    }
  }
}
