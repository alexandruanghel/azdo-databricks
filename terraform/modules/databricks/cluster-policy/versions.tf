terraform {
  required_version = "~> 1.0"

  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
      version = ">= 0.3.5"
    }
  }
}
