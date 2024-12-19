resource "random_password" "secret_password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "kubernetes_secret" "redis_key" {
  metadata {
    name = "redis-encryption-key"
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
        container {
          image = var.container_image
          name  = var.app_name
          image_pull_policy = "IfNotPresent"
          resources {
            requests = {
              cpu    = "250m"
              memory = "500Mi"
            }
            limits = {
              cpu    = "500m"
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
}