terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "azurerm" {
  features {}

  storage_use_azuread = true
}

provider "kubernetes" {
  host                   = module.aks_core.kube_config.host
  client_certificate     = base64decode(module.aks_core.kube_config.client_certificate)
  client_key             = base64decode(module.aks_core.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks_core.kube_config.cluster_ca_certificate)
}