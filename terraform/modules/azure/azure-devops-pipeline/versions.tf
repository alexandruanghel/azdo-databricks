terraform {
  required_version = "~> 1.5.7"

  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.9"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3"
    }
  }
}
