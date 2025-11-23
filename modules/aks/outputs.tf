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

output "oidc_issuer_url" {
  description = "OIDC issuer URL for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  description = "Object ID of the kubelet managed identity used by AKS for pulling images"
}
