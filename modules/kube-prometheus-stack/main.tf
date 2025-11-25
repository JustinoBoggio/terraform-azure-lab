resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace

    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.this.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  # Namespace is created by kubernetes_namespace above
  create_namespace = false

  # Minimal custom values, enough for lab usage
  values = [
    yamlencode({
      grafana = {
        enabled       = true
        adminUser     = var.grafana_admin_user
        adminPassword = var.grafana_admin_password

        service = {
          type = "ClusterIP"
        }

        persistence = {
          enabled = false
        }
      }
    })
  ]

  timeout = 600
}
