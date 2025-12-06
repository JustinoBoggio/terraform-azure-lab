locals {
  location           = "eastus"
  secondary_location = "eastus2"
  env                = "uat"
  owner              = "justino"
  tenant_id          = "004b1179-227e-44f2-b759-e9f05b015b7b"

  common_tags = {
    environment = local.env
    owner       = local.owner
    project     = "terraform-azure-lab"
    managed_by  = "terraform"
  }
}

# ---------------------------------------------------------
# CORE RESOURCES
# ---------------------------------------------------------

module "rg_core" {
  source   = "../../modules/resource-group"
  name     = "rg-core-${local.env}"
  location = local.location
  tags     = local.common_tags
}

module "vnet_core" {
  source = "../../modules/network"

  name                = "vnet-core-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name

  address_space = ["10.30.0.0/16"]

  subnets = {
    "snet-apps" = {
      address_prefixes = ["10.30.1.0/24"]
    }
    "snet-db" = {
      address_prefixes = ["10.30.2.0/24"]
    }
    "snet-aks" = {
      address_prefixes = ["10.30.3.0/24"]
    }
    "snet-appgw" = {
      address_prefixes = ["10.30.4.0/24"]
    }
  }

  tags = local.common_tags
}

module "log_analytics_core" {
  source = "../../modules/log-analytics"

  name                = "law-core-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name
  retention_in_days   = 30
  tags                = local.common_tags
}

# ---------------------------------------------------------
# IDENTITY & SECURITY
# ---------------------------------------------------------

module "kv_core" {
  source = "../../modules/key-vault"

  name                       = "kv-core-${local.env}-${local.owner}"
  location                   = local.location
  resource_group_name        = module.rg_core.name
  tenant_id                  = local.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = local.common_tags
}

# Permissions to the Azure Administrator (Justino)
resource "azurerm_role_assignment" "kv_secrets_officer_current" {
  scope                = module.kv_core.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_object_id
}

resource "azurerm_role_assignment" "kv_certs_officer_current" {
  scope                = module.kv_core.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = var.admin_object_id
}

# Permissions to the Pipeline Service Principal
data "azuread_service_principal" "pipeline_sp" {
  client_id = var.pipeline_client_id
}

resource "azurerm_role_assignment" "kv_certs_officer_pipeline" {
  scope                = module.kv_core.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azuread_service_principal.pipeline_sp.object_id
}

# ---------------------------------------------------------
# COMPUTE (AKS)
# ---------------------------------------------------------

module "aks_core" {
  source = "../../modules/aks"

  name                       = "aks-core-${local.env}"
  location                   = local.location
  resource_group_name        = module.rg_core.name
  dns_prefix                 = "aks-core-${local.env}"
  subnet_id                  = module.vnet_core.subnet_ids["snet-aks"]
  vnet_id                    = module.vnet_core.vnet_id
  log_analytics_workspace_id = module.log_analytics_core.id

  # High availability settings
  node_count          = 2
  node_vm_size        = "Standard_DC2s_v3"
  enable_auto_scaling = true
  min_count           = 2
  max_count           = 4

  tags = local.common_tags
}

module "diag_aks_core" {
  source                     = "../../modules/diagnostic-settings"
  name                       = "ds-aks-core-${local.env}"
  target_resource_id         = module.aks_core.id
  log_analytics_workspace_id = module.log_analytics_core.id

  logs = [
    { category = "kube-apiserver", enabled = true },
    { category = "kube-controller-manager", enabled = true },
    { category = "cluster-autoscaler", enabled = true }
  ]
  metrics = [{ category = "AllMetrics", enabled = true }]
}

# ---------------------------------------------------------
# DATA (SQL)
# ---------------------------------------------------------

resource "random_password" "sql_admin" {
  length           = 24
  special          = true
  override_special = "_%@-"
}

module "sql_core" {
  source = "../../modules/sql-database"

  server_name                  = "sql-core-${local.env}-justino"
  database_name                = "sqldb-core-${local.env}"
  location                     = local.secondary_location
  resource_group_name          = module.rg_core.name
  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_admin.result

  sku_name                      = "S0"
  public_network_access_enabled = false
  tags                          = local.common_tags
}

# Save SQL Admin Password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password-${local.env}"
  value        = random_password.sql_admin.result
  key_vault_id = module.kv_core.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.kv_secrets_officer_current]
}

# Private Endpoint SQL
resource "azurerm_private_dns_zone" "sql_privatelink" {
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg_core.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_privatelink_vnet" {
  name                  = "sql-privatelink-vnet-core-${local.env}"
  resource_group_name   = module.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_privatelink.name
  virtual_network_id    = module.vnet_core.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "pe-sql-core-${local.env}"
  location            = local.location
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

# ---------------------------------------------------------
# CONTAINER REGISTRY (Private)
# ---------------------------------------------------------

module "acr_core" {
  source = "../../modules/acr"

  name                          = "acruat${local.owner}" # Global unique name
  resource_group_name           = module.rg_core.name
  location                      = local.location
  sku                           = "Premium"
  public_network_access_enabled = false
  admin_enabled                 = false
  tags                          = local.common_tags
}

resource "azurerm_private_dns_zone" "acr_dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = module.rg_core.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
  name                  = "link-acr-core-${local.env}"
  resource_group_name   = module.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
  virtual_network_id    = module.vnet_core.vnet_id
}

resource "azurerm_private_endpoint" "acr_pe" {
  name                = "pe-acr-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name
  subnet_id           = module.vnet_core.subnet_ids["snet-apps"]

  private_service_connection {
    name                           = "psc-acr-${local.env}"
    private_connection_resource_id = module.acr_core.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "pdz-acr-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_dns.id]
  }
  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr_core.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks_core.kubelet_identity_object_id
}

# ---------------------------------------------------------
# APP GATEWAY (WAF & TLS)
# ---------------------------------------------------------

# Identity for App Gateway
resource "azurerm_user_assigned_identity" "agw_identity" {
  name                = "mi-appgw-${local.env}"
  resource_group_name = module.rg_core.name
  location            = local.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "agw_kv_access" {
  scope                = module.kv_core.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agw_identity.principal_id
}

# SSL Certificate in Key Vault
resource "azurerm_key_vault_certificate" "app_cert" {
  name         = "cert-hello-api-${local.env}"
  key_vault_id = module.kv_core.id

  certificate_policy {
    issuer_parameters { name = "Self" }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    lifetime_action {
      action { action_type = "AutoRenew" }
      trigger { days_before_expiry = 30 }
    }
    secret_properties { content_type = "application/x-pkcs12" }
    x509_certificate_properties {
      subject            = "CN=hello-uat.local"
      validity_in_months = 12
      key_usage          = ["cRLSign", "dataEncipherment", "digitalSignature", "keyEncipherment", "keyAgreement", "keyCertSign"]
      subject_alternative_names {
        dns_names = ["hello-uat.local"]
      }
    }
  }
  tags = local.common_tags
}

module "app_gateway_core" {
  source = "../../modules/app-gateway"

  name                 = "agw-core-${local.env}"
  location             = local.location
  resource_group_name  = module.rg_core.name
  subnet_id            = module.vnet_core.subnet_ids["snet-appgw"]
  backend_port         = 30141
  backend_ip_addresses = ["10.30.3.10"]
  identity_ids         = [azurerm_user_assigned_identity.agw_identity.id]

  ssl_certificates = [
    {
      name                = "cert-hello-uat"
      key_vault_secret_id = azurerm_key_vault_certificate.app_cert.versionless_secret_id
    }
  ]

  host_name = "hello-uat.local"
  tags      = local.common_tags
}

# ---------------------------------------------------------
# KUBERNETES RESOURCES
# ---------------------------------------------------------

module "kube_baseline" {
  source      = "../../modules/kube-baseline"
  environment = local.env
  owner       = local.owner
}

module "nginx_ingress" {
  source        = "../../modules/nginx-ingress"
  environment   = local.env
  owner         = local.owner
  namespace     = "ingress-nginx"
  release_name  = "ingress-nginx"
  replica_count = 2
  service_type  = "NodePort"
  nodeport_http = 30141
}

module "hello_api_identity" {
  source                     = "../../modules/workload-identity"
  name                       = "mi-hello-api-${local.env}"
  location                   = local.location
  resource_group_name        = module.rg_core.name
  kubernetes_oidc_issuer_url = module.aks_core.oidc_issuer_url
  namespace                  = "apps"
  service_account_name       = "hello-api-sa"
  key_vault_id               = module.kv_core.id
  tags                       = local.common_tags
}

resource "kubernetes_service_account" "hello_api" {
  metadata {
    name        = "hello-api-sa"
    namespace   = "apps"
    labels      = { "azure.workload.identity/use" = "true" }
    annotations = { "azure.workload.identity/client-id" = module.hello_api_identity.client_id }
  }
}

resource "azurerm_key_vault_secret" "hello_api_message" {
  name         = "hello-api-message"
  value        = "Hello from UAT Environment - Ready for Testing!"
  key_vault_id = module.kv_core.id
  tags         = local.common_tags
  depends_on   = [azurerm_role_assignment.kv_secrets_officer_current]
}

module "sample_app" {
  source      = "../../modules/sample-app"
  environment = local.env
  owner       = local.owner
  namespace   = "apps"
  app_name    = "hello-api"

  image = "${module.acr_core.login_server}/hello-api:uat"

  replicas                   = 2
  container_port             = 80
  service_account_name       = kubernetes_service_account.hello_api.metadata[0].name
  secret_provider_class_name = "spc-hello-api"
  host                       = "hello-uat.local"

  env_vars = {
    KEYVAULT_URL = module.kv_core.vault_uri
    SECRET_NAME  = "hello-api-message"
    ENVIRONMENT  = local.env
  }
}

# ---------------------------------------------------------
# RUNNER INFRASTRUCTURE (Multi-Region)
# ---------------------------------------------------------

module "vnet_runner" {
  source              = "../../modules/network"
  name                = "vnet-runner-${local.env}"
  location            = local.secondary_location
  resource_group_name = module.rg_core.name

  address_space = ["10.40.0.0/16"]

  subnets = {
    "snet-runner" = {
      address_prefixes = ["10.40.1.0/24"]
    }
  }
  tags = local.common_tags
}

# Global Peering (UAT Core <-> UAT Runner)
resource "azurerm_virtual_network_peering" "core_to_runner" {
  name                      = "peer-core-to-runner"
  resource_group_name       = module.rg_core.name
  virtual_network_name      = module.vnet_core.vnet_name
  remote_virtual_network_id = module.vnet_runner.vnet_id
}

resource "azurerm_virtual_network_peering" "runner_to_core" {
  name                      = "peer-runner-to-core"
  resource_group_name       = module.rg_core.name
  virtual_network_name      = module.vnet_runner.vnet_name
  remote_virtual_network_id = module.vnet_core.vnet_id
}

# DNS Link so the Runner can resolve ACR Private Endpoint
resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link_runner" {
  name                  = "link-acr-runner-${local.env}"
  resource_group_name   = module.rg_core.name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
  virtual_network_id    = module.vnet_runner.vnet_id
}

# Runner VM
resource "tls_private_key" "runner_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.runner_ssh.private_key_pem
  filename        = "${path.module}/runner-key.pem"
  file_permission = "0600"
}

module "runner_vm" {
  source              = "../../modules/linux-vm"
  name                = "vm-runner-${local.env}"
  resource_group_name = module.rg_core.name
  location            = local.secondary_location
  subnet_id           = module.vnet_runner.subnet_ids["snet-runner"]
  vm_size             = "Standard_B2s"

  # Install tools script
  custom_data        = filebase64("${path.module}/scripts/install-tools.sh")
  public_key_content = tls_private_key.runner_ssh.public_key_openssh
  tags               = local.common_tags
}

module "nsg_runner" {
  source              = "../../modules/nsg"
  name                = "nsg-runner-${local.env}"
  location            = local.secondary_location
  resource_group_name = module.rg_core.name
  subnet_id           = module.vnet_runner.subnet_ids["snet-runner"]
  tags                = local.common_tags

  security_rules = [
    {
      name                       = "AllowSSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.ssh_source_ip
      destination_address_prefix = "*"
    }
  ]
}

# NSG Core (AKS & AppGW)
module "nsg_aks" {
  source              = "../../modules/nsg"
  name                = "nsg-aks-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name
  subnet_id           = module.vnet_core.subnet_ids["snet-aks"]
  tags                = local.common_tags
}

resource "azurerm_network_security_rule" "allow_appgw_to_aks" {
  name                        = "AllowAppGwToAKS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "30000-32767"
  source_address_prefix       = "10.30.4.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = module.rg_core.name
  network_security_group_name = module.nsg_aks.nsg_name
}

module "nsg_appgw" {
  source              = "../../modules/nsg"
  name                = "nsg-appgw-${local.env}"
  location            = local.location
  resource_group_name = module.rg_core.name
  subnet_id           = module.vnet_core.subnet_ids["snet-appgw"]
  tags                = local.common_tags

  security_rules = [
    {
      name                       = "AllowGatewayManager"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowInternetHTTP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowInternetHTTPS"
      priority                   = 111
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }
  ]
}