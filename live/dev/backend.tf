terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "statfstatejustino"
    container_name       = "tfstate-dev"
    key                  = "infra-dev.tfstate"
  }
}