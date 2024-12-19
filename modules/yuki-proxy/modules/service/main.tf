resource "kubernetes_service" "yuki-proxy" {
  metadata {
    name = var.app_name
    namespace = var.namespace
    labels = {
      group = var.app_group
      app = var.app_name
      "app.kubernetes.io/name" = var.app_name
    }
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      port        = var.app_port
      target_port = var.app_port
    }
    type = "NodePort"
  }
}