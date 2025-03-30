terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  nging_config = "nginx-config"
}

resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = local.nging_config
    namespace = var.namespace
  }

  data = {
    "nginx.conf" = <<-EOF
      events {
        worker_connections 1024;
      }
      http {
        upstream backend {
          server ${var.proxy_enabled.host}:${var.proxy_enabled.port};
          server ${var.proxy_disabled.host}:${var.proxy_disabled.port} backup;
        }
        
        server {
          listen 80;
          location / {
            proxy_pass http://backend;
            proxy_next_upstream error invalid_header;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
          }
        }
      }
    EOF
  }
}

resource "kubernetes_deployment" "nginx_proxy" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
  }

  spec {
    replicas = 5

    selector {
      match_labels = {
        app = var.service_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.service_name
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:stable"
          
          resources {
            requests = {
              cpu    = "500m"
              memory = "500Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
          
          port {
            container_port = 80
          }

          volume_mount {
            name       = "nginx-config-volume"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }
        }

        volume {
          name = "nginx-config-volume"

          config_map {
            name = local.nging_config
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_proxy_service" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
  }

  spec {
    type = "NodePort"
    selector = {
      app = "nginx-proxy"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "nginx_proxy_hpa" {
  metadata {
    name      = "${var.service_name}-hpa"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      kind = "Deployment"
      name = var.service_name
      api_version = "apps/v1"
    }

    min_replicas = 5
    max_replicas = 20

    target_cpu_utilization_percentage = 40
  }
}

