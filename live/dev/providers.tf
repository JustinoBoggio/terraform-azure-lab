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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "azurerm" {
  features {}

  # Use Azure AD for storage APIs when needed
  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}

provider "kubernetes" {
  host                   = module.aks_core.kube_config.host
  client_certificate     = base64decode(module.aks_core.kube_config.client_certificate)
  client_key             = base64decode(module.aks_core.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks_core.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks_core.kube_config.host
    client_certificate     = base64decode(module.aks_core.kube_config.client_certificate)
    client_key             = base64decode(module.aks_core.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks_core.kube_config.cluster_ca_certificate)
  }
}