output "service_name" {
  description = "Kubernetes service name"
  value       = kubernetes_service.app.metadata[0].name
}

output "ingress_name" {
  description = "Kubernetes ingress name"
  value       = kubernetes_ingress_v1.app.metadata[0].name
}
