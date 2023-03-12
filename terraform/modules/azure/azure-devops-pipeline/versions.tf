terraform {
  required_version = "~> 1.4"

  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.3.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}
