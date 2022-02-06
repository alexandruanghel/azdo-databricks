terraform {
  required_version = "~> 1.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.95"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.1.8"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
