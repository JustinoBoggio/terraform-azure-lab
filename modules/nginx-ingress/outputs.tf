output "namespace" {
  description = "Namespace where ingress-nginx is installed"
  value       = kubernetes_namespace.ingress.metadata[0].name
}