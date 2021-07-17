terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.68"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
