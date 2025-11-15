resource "kubernetes_service_account" "app_deployer" {
  metadata {
    name      = "app-deployer"
    namespace = var.namespace
    labels = {
      environment = var.environment
      owner       = var.owner
      role        = "deployer"
    }
  }
}

resource "kubernetes_service_account" "app_viewer" {
  metadata {
    name      = "app-viewer"
    namespace = var.namespace
    labels = {
      environment = var.environment
      owner       = var.owner
      role        = "viewer"
    }
  }
}

resource "kubernetes_role" "deployer" {
  metadata {
    name      = "apps-deployer"
    namespace = var.namespace
    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }

  rule {
    api_groups = ["", "apps"]
    resources  = ["pods", "deployments", "services", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role" "viewer" {
  metadata {
    name      = "apps-viewer"
    namespace = var.namespace
    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }

  rule {
    api_groups = ["", "apps"]
    resources  = ["pods", "deployments", "services", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "deployer_binding" {
  metadata {
    name      = "apps-deployer-binding"
    namespace = var.namespace
    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.deployer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.app_deployer.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_role_binding" "viewer_binding" {
  metadata {
    name      = "apps-viewer-binding"
    namespace = var.namespace
    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.viewer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.app_viewer.metadata[0].name
    namespace = var.namespace
  }
}