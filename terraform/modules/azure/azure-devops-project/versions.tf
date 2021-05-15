terraform {
  required_version = "~> 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.58"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.1.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
