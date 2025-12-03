terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.54.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 4.54.0"
    }
  }
}

provider "azurerm" {
  features {}
}
