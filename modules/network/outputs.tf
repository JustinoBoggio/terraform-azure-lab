output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnets" {
  value = {
    for k, s in azurerm_subnet.this : k => {
      id   = s.id
      name = s.name
    }
  }
}