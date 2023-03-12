terraform {
  required_version = "~> 1.4"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.36"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}
