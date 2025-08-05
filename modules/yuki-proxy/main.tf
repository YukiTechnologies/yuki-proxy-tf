terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.81.0, < 6.0.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16, < 3.0"
    }
  }
}


locals {
  proxy_name = "yuki-proxy"
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.0"
}

resource "helm_release" "yuki_helm_chart" {
  name       = "yuki"
  repository = "https://yukitechnologies.github.io/yuki-proxy-chart"
  chart      = "proxy"
  namespace  = var.namespace
  version    = var.yuki_helm_chart_version

  create_namespace = true

  values = [
    yamlencode({
      app = {
        name         = local.proxy_name
        group        = var.app_group
        replicaCount = var.proxy_min_replicas
        container = {
          image = var.container_image
          port = tonumber(var.app_port)
          env = merge({
            ASPNETCORE_ENVIRONMENT = "Prod"
            REDIS_HOST             = var.elasticache_endpoint_url
            PROXY_ENABLED          = "true"
            COMPUTE_HOST           = var.compute_host
            SYSTEM_HOST            = var.system_host
          }, var.proxy_environment_variables)
        }
        service = {
          type = "NodePort"
          port = tonumber(var.app_port)
          targetPort = tonumber(var.app_port)
        }
      }

      redisSecret = {
        create = true
      }
      hpa = {
        enabled                            = true
        minReplicas                       = var.proxy_min_replicas
        maxReplicas                       = var.proxy_max_replicas
        targetCPUUtilizationPercentage    = 40
        targetMemoryUtilizationPercentage = 40
      }
      
      ingress = {
        enabled = false
      }
      
      resources = {
        requests = {
          cpu    = "1000m"
          memory = "500Mi"
        }
        limits = {
          memory = "1Gi"
        }
      }
    })
  ]
}


module "yuki_proxy_private_alb" {
  source             = "./modules/alb"
  count              = var.create_private_load_balancer ? 1 : 0
  internal           = true
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  app_name           = local.proxy_name
  app_port           = var.app_port
  namespace          = var.namespace
  load_balancer_name = var.load_balancer_name
  certificate_arn    = var.private_certificate_arn
  path               = var.path
  depends_on = [helm_release.yuki_helm_chart]
}

module "yuki_proxy_public_alb" {
  source             = "./modules/alb"
  count              = var.create_public_load_balancer ? 1 : 0
  internal           = false
  vpc_id             = var.vpc_id
  subnet_ids         = var.public_subnet_ids
  app_name           = local.proxy_name
  app_port           = var.app_port
  namespace          = var.namespace
  load_balancer_name = var.load_balancer_name
  certificate_arn    = var.public_certificate_arn
  path               = var.path
  depends_on = [helm_release.yuki_helm_chart]
}

module "yuki_proxy_private_link" {
  source              = "./modules/nlb"
  count               = var.private_link_config != null ? 1 : 0
  namespace           = var.namespace
  app_name            = local.proxy_name
  app_port            = var.app_port
  private_link_config = var.private_link_config
  load_balancer_name  = var.load_balancer_name
  subnet_ids          = var.private_subnet_ids
  vpc_id              = var.vpc_id
  vpc_cidr            = var.vpc_cidr
  certificate_arn     = var.private_certificate_arn
  depends_on = [helm_release.yuki_helm_chart]
}

