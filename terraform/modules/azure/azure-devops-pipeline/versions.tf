terraform {
  required_version = "~> 0.14"

  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.1.4"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
