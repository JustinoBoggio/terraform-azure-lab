locals {
  location  = "eastus"
  sql_location = "eastus2"
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

resource "azurerm_monitor_action_group" "email_justino_action_group" {
  name                = "ag-${local.env}-justino-email"
  resource_group_name = module.rg_core.name
  short_name          = "${local.env}-email"

  email_receiver {
    name                    = "justino-email"
    email_address           = "justinoboggio@hotmail.com"
    use_common_alert_schema = true
  }

  tags = local.common_tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pods_restarts_apps" {
  name                = "alert-pod-restarts-apps-${local.env}"
  resource_group_name = module.rg_core.name
  location            = local.location

  display_name = "Dev - Pods with restarts in namespace apps"
  description  = "Alert when any pod in namespace 'apps' has ContainerRestartCount > 0 in AKS dev cluster"
  severity     = 3
  enabled      = true

  # Scope: Log Analytics workspace of dev
  scopes = [
    module.log_analytics_core.id
  ]

  evaluation_frequency = "PT5M"  # Every 5 minutes
  window_duration      = "PT15M" # Look at last 15 minutes

  criteria {
    query = <<-KQL
      KubePodInventory
      | where ClusterName == "aks-core-dev"
      | where Namespace == "apps"
      | summarize MaxRestarts = max(ContainerRestartCount)
      | where MaxRestarts > 0
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      number_of_evaluation_periods             = 1
      minimum_failing_periods_to_trigger_alert = 1
    }
  }

  action {
    action_groups = [
      azurerm_monitor_action_group.email_justino_action_group.id
    ]
  }

  tags = local.common_tags
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

resource "azurerm_role_assignment" "kv_secrets_officer_current" {
  scope                = module.kv_core.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
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

resource "random_password" "sql_admin" {
  length           = 24
  special          = true
  override_special = "_%@-" # avoid problems with some characters
}

module "sql_core" {
  source = "../../modules/sql-database"

  server_name         = "sql-core-${local.env}-justino"
  database_name       = "sqldb-core-${local.env}"
  location            = local.sql_location
  resource_group_name = module.rg_core.name

  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_admin.result

  sku_name = "Basic"
  public_network_access_enabled = false

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "sql_admin_password_dev" {
  name         = "sql-admin-password-${local.env}"
  value        = random_password.sql_admin.result
  key_vault_id = module.kv_core.id

  tags = local.common_tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name      = "allow-azure-services"
  server_id = module.sql_core.server_id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Private DNS zone for Azure SQL private endpoints
resource "azurerm_private_dns_zone" "sql_privatelink" {
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg_core.name

  tags = local.common_tags
}

# Link the private DNS zone to the core VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_privatelink_vnet" {
  name                  = "sql-privatelink-vnet-core-${local.env}"
  resource_group_name   = module.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_privatelink.name
  virtual_network_id    = module.vnet_core.vnet_id

  registration_enabled = false
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "pe-sql-core-${local.env}"
  location            = local.location              # same region as VNet (eastus)
  resource_group_name = module.rg_core.name
  subnet_id           = module.vnet_core.subnet_ids["snet-db"]

  private_service_connection {
    name                           = "sql-core-${local.env}-connection"
    private_connection_resource_id = module.sql_core.server_id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-privatelink-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_privatelink.id]
  }

  tags = local.common_tags
}

module "diag_aks_core" {
  source = "../../modules/diagnostic-settings"

  name                       = "ds-aks-core-${local.env}"
  target_resource_id         = module.aks_core.id
  log_analytics_workspace_id = module.log_analytics_core.id

  # AKS control plane logs
  logs = [
    {
      category = "kube-apiserver"
      enabled  = true
    },
    {
      category = "kube-controller-manager"
      enabled  = true
    },
    {
      category = "kube-scheduler"
      enabled  = true
    },
    {
      category = "cluster-autoscaler"
      enabled  = true
    }
  ]

  # AKS metrics
  metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}

module "kube_baseline" {
  source      = "../../modules/kube-baseline"
  environment = local.env
  owner       = local.owner
}

resource "kubernetes_service_account" "hello_api" {
  metadata {
    name      = "hello-api-sa"
    namespace = "apps"

    labels = {
      "azure.workload.identity/use" = "true"
    }

    annotations = {
      "azure.workload.identity/client-id" = module.hello_api_identity.client_id
    }
  }
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

  service_type = "ClusterIP"
}

module "sample_app" {
  source      = "../../modules/sample-app"
  environment = local.env
  owner       = local.owner

  namespace      = "apps"
  app_name       = "hello-api"
  image          = "${module.acr_core.login_server}/hello-api:dev"
  replicas       = 1
  container_port = 80

  service_account_name       = kubernetes_service_account.hello_api.metadata[0].name
  secret_provider_class_name = "spc-hello-api"

  host = "hello-dev.local"

  env_vars = {
    KEYVAULT_URL = module.kv_core.vault_uri
    SECRET_NAME  = "hello-api-message"
    ENVIRONMENT  = local.env
  }
}

module "hello_api_identity" {
  source = "../../modules/workload-identity"

  name                = "mi-hello-api-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name

  kubernetes_oidc_issuer_url = module.aks_core.oidc_issuer_url

  namespace            = "apps"
  service_account_name = "hello-api-sa"

  key_vault_id = module.kv_core.id
  tags         = local.common_tags
}

resource "azurerm_key_vault_secret" "hello_api_message" {
  name         = "hello-api-message"
  value        = "Hello from Key Vault in dev!"
  key_vault_id = module.kv_core.id

  tags = local.common_tags

  depends_on = [
    azurerm_role_assignment.kv_secrets_officer_current
  ]
}

module "acr_core" {
  source = "../../modules/acr"

  # This will result in "acrdevjustino"
  name                = "acr${local.env}${local.owner}"
  resource_group_name = module.rg_core.name
  location            = local.location

  sku           = "Basic"
  admin_enabled = false

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr_core.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks_core.kubelet_identity_object_id
}

module "monitoring_stack" {
  source = "../../modules/kube-prometheus-stack"

  environment            = local.env
  owner                  = local.owner
  grafana_admin_user     = "admin"
  grafana_admin_password = "DevGrafana123!" # only for lab purposes
}
