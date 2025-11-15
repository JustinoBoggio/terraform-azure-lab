resource "kubernetes_namespace" "platform" {
  metadata {
    name = "platform"

    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"

    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }
}

resource "kubernetes_limit_range" "apps_default" {
  metadata {
    name      = "default-limits"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      # Default limits for containers that do not specify resources
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }

      # Default requests for containers that do not specify resources
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
}
