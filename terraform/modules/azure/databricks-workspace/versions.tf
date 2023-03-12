terraform {
  required_version = "~> 1.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.47"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}
