output "rg_core_name" {
  value = module.rg_core.name
}

output "vnet_core_name" {
  value = module.vnet_core.vnet_name
}

output "subnets" {
  value = module.vnet_core.subnets
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the dev Log Analytics workspace"
  value       = module.log_analytics_core.id
}

output "key_vault_uri" {
  description = "URI of the dev Key Vault"
  value       = module.kv_core.vault_uri
}

output "runner_ssh_command" {
  value = "ssh -i runner-key.pem azureuser@${module.runner_vm.public_ip}"
}