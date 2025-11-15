output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Map of subnet names to their ids"
  value       = { for s in azurerm_subnet.this : s.name => s.id }
}

output "subnets" {
  value = {
    for k, s in azurerm_subnet.this : k => {
      id   = s.id
      name = s.name
    }
  }
}