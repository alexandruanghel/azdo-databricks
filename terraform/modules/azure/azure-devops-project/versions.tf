terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.68"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.1.6"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
