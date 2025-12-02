output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "id" {
  description = "The ID of the Application Gateway"
  value       = azurerm_application_gateway.this.id
}