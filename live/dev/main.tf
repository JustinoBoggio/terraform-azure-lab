locals {
  location  = "eastus"
  env       = "dev"
  tenant_id = "004b1179-227e-44f2-b759-e9f05b015b7b"
  common_tags = {
    environment = local.env
    owner       = "justino"
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

  name                = "kv-core-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name
  tenant_id           = local.tenant_id

  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = local.common_tags
}