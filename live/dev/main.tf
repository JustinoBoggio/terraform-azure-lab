locals {
  location  = "eastus"
  env       = "dev"
  tenant_id = "004b1179-227e-44f2-b759-e9f05b015b7b"
  owner     = "justino"
  common_tags = {
    environment = local.env
    owner       = local.owner
    project     = "terraform-azure-lab"
  }
}

# Main Resource group for dev
module "rg_core" {
  source   = "../../modules/resource-group"
  name     = "rg-core-${local.env}"
  location = local.location
  tags     = local.common_tags
}

# Main Net for dev
module "vnet_core" {
  source = "../../modules/network"

  name                = "vnet-core-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name
  address_space       = ["10.10.0.0/16"]

  subnets = {
    "snet-apps" = {
      address_prefixes = ["10.10.1.0/24"]
    }
    "snet-db" = {
      address_prefixes = ["10.10.2.0/24"]
    }
    "snet-aks" = {
      address_prefixes = ["10.10.3.0/24"]
    }
  }

  tags = local.common_tags
}

# Shared Log Analytics workspace for dev
module "log_analytics_core" {
  source = "../../modules/log-analytics"

  name                = "law-core-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name

  retention_in_days = 30
  tags              = local.common_tags
}

# Shared Key Vault for dev (RBAC enabled)
module "kv_core" {
  source = "../../modules/key-vault"

  name                = "kv-core-${local.env}-${local.owner}"
  location            = local.location
  resource_group_name = module.rg_core.name
  tenant_id           = local.tenant_id

  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = local.common_tags
}

module "diag_kv_core" {
  source = "../../modules/diagnostic-settings"

  name                       = "ds-kv-core-${local.env}"
  target_resource_id         = module.kv_core.id
  log_analytics_workspace_id = module.log_analytics_core.id

  logs = [
    {
      category = "AuditEvent"
      enabled  = true
    }
  ]

  metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}

module "aks_core" {
  source = "../../modules/aks"

  name                = "aks-core-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name
  dns_prefix          = "aks-core-${local.env}"

  subnet_id                  = module.vnet_core.subnet_ids["snet-aks"]
  vnet_id                    = module.vnet_core.vnet_id
  log_analytics_workspace_id = module.log_analytics_core.id

  # kubernetes_version = "1.29.2"
  node_count          = 1
  node_vm_size        = "Standard_DC2s_v3"
  enable_auto_scaling = false

  tags = local.common_tags
}

module "kube_baseline" {
  source      = "../../modules/kube-baseline"
  environment = local.env
  owner       = local.owner
}

module "kube_rbac_apps" {
  source      = "../../modules/kube-rbac"
  environment = local.env
  namespace   = "apps"
  owner       = local.owner
}

module "nginx_ingress" {
  source      = "../../modules/nginx-ingress"
  environment = local.env
  owner       = local.owner

  namespace     = "ingress-nginx"
  release_name  = "ingress-nginx"
  replica_count = 1
}
