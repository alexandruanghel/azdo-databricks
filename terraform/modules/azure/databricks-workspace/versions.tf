terraform {
  required_version = "~> 1.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.95"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
