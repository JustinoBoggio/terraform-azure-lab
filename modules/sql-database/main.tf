resource "azurerm_mssql_server" "this" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location

  // Version 12.0 is required for Azure SQL
  version                      = "12.0"

  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password

  // Basic security hardening for the lab
  minimum_tls_version          = "1.2"
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags
}

resource "azurerm_mssql_database" "this" {
  name      = var.database_name
  server_id = azurerm_mssql_server.this.id
  sku_name  = var.sku_name

  // Small size for the lab
  max_size_gb = 2

  tags = var.tags
}
