terraform {
  required_version = "~> 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.59"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
