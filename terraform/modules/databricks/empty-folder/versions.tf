terraform {
  required_version = "~> 0.14"

  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
      version = ">= 0.3.4"
    }
  }
}
