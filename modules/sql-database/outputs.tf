output "server_name" {
  description = "SQL server name."
  value       = azurerm_mssql_server.this.name
}

output "database_name" {
  description = "SQL database name."
  value       = azurerm_mssql_database.this.name
}

output "fqdn" {
  description = "Fully qualified DNS name of the SQL server."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "connection_string" {
  description = "Connection string for the SQL database using SQL authentication."
  value = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.this.name};Persist Security Info=False;User ID=${var.administrator_login};Password=${var.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive = true
}

output "server_id" {
  value = azurerm_mssql_server.this.id
}
