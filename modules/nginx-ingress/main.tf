resource "kubernetes_namespace" "ingress" {
  metadata {
    name = var.namespace

    labels = {
      environment = var.environment
      owner       = var.owner
      app         = "nginx-ingress"
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name       = var.release_name
  namespace  = kubernetes_namespace.ingress.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  wait   = false
  atomic = false

  values = [
    yamlencode({
      controller = {
        replicaCount = var.replica_count
        service = {
          type = "ClusterIP"
        }
        metrics = {
          enabled = true
        }
        podLabels = {
          environment = var.environment
          owner       = var.owner
        }
      }
    })
  ]
}

