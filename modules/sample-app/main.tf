locals {
  labels = {
    app         = var.app_name
    environment = var.environment
    owner       = var.owner
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = merge(
          local.labels,
          {
            "azure.workload.identity/use" = "true"
          }
        )
      }

      spec {
        service_account_name = var.service_account_name

        volume {
          name = "secrets-store-inline"

          csi {
            driver = "secrets-store.csi.k8s.io"
            read_only = true

            volume_attributes = {
              secretProviderClass = var.secret_provider_class_name
            }
          }
        }

        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = var.container_port
          }

          image_pull_policy = "Always"

          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "secrets-store-inline"
            mount_path = "/mnt/secrets-store"
            read_only  = true
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.app_name}-svc"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = 80
      target_port = var.container_port
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = var.host != "" ? var.host : null

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
