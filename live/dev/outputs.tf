output "rg_core_name" {
  value = module.rg_core.name
}

output "vnet_core_name" {
  value = module.vnet_core.vnet_name
}

output "subnets" {
  value = module.vnet_core.subnets
}