terraform {
  required_version = "~> 1.5.7"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.41"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3"
    }
  }
}
