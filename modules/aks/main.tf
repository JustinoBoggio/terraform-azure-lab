resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  # kubernetes_version               = var.kubernetes_version
  role_based_access_control_enabled = true

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size

    os_disk_size_gb = 30
    os_disk_type    = "Managed"

    vnet_subnet_id = var.subnet_id
    max_pods       = 30

    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_count : null
    max_count           = var.enable_auto_scaling ? var.max_count : null

    type = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "33%"
    }
  }


  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  network_profile {
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
    network_plugin = "azure"
    network_policy = "azure"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
    # optional settings:
    # secret_rotation_interval = "2m"
  }
  #local_account_disabled = true

  tags = var.tags
}

# Give the AKS managed identity permissions on the VNet
resource "azurerm_role_assignment" "network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}