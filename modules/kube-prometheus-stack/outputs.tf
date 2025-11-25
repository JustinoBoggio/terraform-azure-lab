output "namespace" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "grafana_service_name" {
  value = "kube-prometheus-stack-grafana"
}
