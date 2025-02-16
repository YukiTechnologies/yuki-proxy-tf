resource "kubernetes_cron_job" "system_monitoring_job" {
  metadata {
    name      = var.cron_name
    namespace = var.namespace
  }

  spec {
    schedule = "*/1 * * * *"

    job_template {
      metadata {
        labels = {
          "job-name" = "${var.cron_name}-job"
        }
      }
      spec {
        template {
          metadata {
            labels = {
              "job-name" = "${var.cron_name}-job"
            }
          }
          spec {
            container {
              name  = "${var.cron_name}-job"
              image = var.image

              env {
                name  = "SYSTEM_URL"
                value = var.system_url
              }

              env {
                name  = "COMPUTE_URL"
                value = var.compute_url
              }

              env {
                name  = "REDIS_HOST"
                value = var.redis_host
              }

              env {
                name  = "SYSTEM_REDIS_KEY"
                value = "yuki-system-monitoring"
              }

              env {
                name  = "COMPUTE_REDIS_KEY"
                value = "yuki-compute-monitoring"
              }
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
