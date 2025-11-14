output "rg_core_name" {
  description = "Name of the core resource group for UAT"
  value       = module.rg_core.name
}

output "vnet_core_name" {
  description = "Name of the core virtual network for UAT"
  value       = module.vnet_core.vnet_name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the UAT Log Analytics workspace"
  value       = module.log_analytics_core.id
}

output "key_vault_uri" {
  description = "URI of the UAT Key Vault"
  value       = module.kv_core.vault_uri
}