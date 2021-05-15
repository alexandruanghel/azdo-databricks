terraform {
  required_version = "~> 0.14"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 1.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
