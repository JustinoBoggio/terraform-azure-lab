output "id" {
  description = "AKS cluster id"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description = "Kube config for admin access to the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config[0]
  sensitive   = true
}