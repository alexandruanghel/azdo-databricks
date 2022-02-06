terraform {
  required_version = "~> 1.1"

  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.1.8"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
