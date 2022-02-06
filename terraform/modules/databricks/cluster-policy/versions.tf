terraform {
  required_version = "~> 1.1"

  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
      version = ">= 0.4.8"
    }
  }
}
