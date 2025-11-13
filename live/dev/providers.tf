terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}

  # Force OIDC in CI
  use_oidc            = true
  use_cli             = false
  storage_use_azuread = true
}