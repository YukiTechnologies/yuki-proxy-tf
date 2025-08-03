terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
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

module "system_monitoring_job" {
  source      = "./modules/system-monitoring"
  system_url  = "${var.system_host}/health"
  compute_url = "${var.compute_host}/compute/health"
  cron_name   = "yuki-system-monitoring"
  image       = "406122784773.dkr.ecr.us-east-1.amazonaws.com/system-monitoring-job:0.0.16"
  namespace   = var.namespace
  redis_host  = var.elasticache_endpoint_url
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_enabled_proxy_service" {
  source = "./modules/service"

  namespace = var.namespace
  app_group = var.app_group
  app_name  = local.proxy_name
  app_port  = var.app_port
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_enabled_proxy_deployment" {
  source = "./modules/deployment"

  namespace                   = var.namespace
  app_group                   = var.app_group
  app_name                    = local.proxy_name
  app_port                    = var.app_port
  container_image             = var.container_image
  deployment_replicas         = var.proxy_min_replicas
  proxy_enabled               = "true"
  proxy_environment_variables = var.proxy_environment_variables
  elasticache_endpoint        = var.elasticache_endpoint_url
  redis_key_name              = "enb-redis-encryption-key"

  depends_on = [kubernetes_namespace.namespace]
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
  depends_on = [kubernetes_namespace.namespace]
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
  depends_on = [kubernetes_namespace.namespace]
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
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_enabled_proxy_hpa" {
  source                 = "./modules/hpa"
  min_replicas           = var.proxy_min_replicas
  max_replicas           = var.proxy_max_replicas
  target_cpu_utilization = 30
  namespace              = var.namespace
  app_name               = local.proxy_name
  depends_on = [kubernetes_namespace.namespace]
}