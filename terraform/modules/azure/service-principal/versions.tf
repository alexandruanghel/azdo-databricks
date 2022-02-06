terraform {
  required_version = "~> 1.1"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
