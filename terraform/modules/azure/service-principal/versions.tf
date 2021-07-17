terraform {
  required_version = "~> 1.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 1.6"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
