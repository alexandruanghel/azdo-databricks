terraform {
  required_version = "~> 1.5.6"

  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.8"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3"
    }
  }
}
