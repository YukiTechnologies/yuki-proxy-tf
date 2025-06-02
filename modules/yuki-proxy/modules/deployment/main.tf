resource "random_password" "secret_password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "kubernetes_secret" "redis_key" {
  metadata {
    name = var.redis_key_name
    namespace = var.namespace
  }

  data = {
    redis_key = base64encode(random_password.secret_password.result)
  }
}

resource "kubernetes_deployment" "yuki-proxy" {
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
    replicas = var.deployment_replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
          group = var.app_group
        }
      }

      spec {
        termination_grace_period_seconds = 90

        container {
          image = var.container_image
          name  = var.app_name
          image_pull_policy = "IfNotPresent"

          readiness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 1
            success_threshold     = 2
            failure_threshold     = 3
          }

          lifecycle {
            pre_stop {
              exec {
                command = ["/bin/sh", "-c", "sleep 60"]
              }
            }
          }

          resources {
            requests = {
              cpu    = "1000m"
              memory = "500Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
          port {
            container_port = var.app_port
          }
          env {
            name = "REDIS_ENCRYPTION_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.redis_key.metadata[0].name
                key  = "redis_key"
              }
            }
          }
          env {
            name = "REDIS_HOST"
            value = var.elastic_cache_endpoint
          }
          env {
            name = "ASPNETCORE_ENVIRONMENT"
            value = "Prod"
          }
          env {
            name = "PROXY_ENABLED"
            value = var.proxy_enabled
          }
          dynamic "env" {
            for_each = var.proxy_environment_variables
            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].replicas
    ]
  }
}
