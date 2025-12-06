resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  backend_address_pool {
    name         = "aks-nginx-backend"
    ip_addresses = var.backend_ip_addresses
}


probe {
    name                = "probe-${var.name}"
    protocol            = "Http"
    path                = "/"
    host                = var.host_name
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    
    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                  = "http-settings"
    protocol              = "Http"
    port                  = var.backend_port
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    
    host_name             = var.host_name
    probe_name            = "probe-${var.name}"
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "httpsPort"
    protocol                       = "Https"
    ssl_certificate_name           = var.ssl_certificates[0].name
  }

  request_routing_rule {
    name                       = "rr-hello-api"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "aks-nginx-backend"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}
