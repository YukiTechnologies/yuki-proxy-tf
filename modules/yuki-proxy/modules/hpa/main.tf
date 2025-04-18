terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
}
resource "kubernetes_horizontal_pod_autoscaler" "yuki_proxy_hpa" {
  metadata {
    name      = "${var.app_name}-hpa"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      kind = "Deployment"
      name = var.app_name
      api_version = "apps/v1"
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
    target_cpu_utilization_percentage = var.target_cpu_utilization
  }
}