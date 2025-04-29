terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

locals {
  nginx_proxy    = "nginx-proxy"
  enabled_proxy  = "yuki-proxy-enabled"
  disabled_proxy = "yuki-proxy-disabled"
  nginx_port     = "80"
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.0"
}

module "nginx_proxy" {
  source       = "./modules/nginx-proxy"
  namespace    = var.namespace
  service_name = local.nginx_proxy
  proxy_disabled = {
    host = local.disabled_proxy
    port = var.app_port
  }
  proxy_enabled = {
    host = local.enabled_proxy
    port = var.app_port
  }
  depends_on = [kubernetes_namespace.namespace]
}

module "system_monitoring_job" {
  source      = "./modules/system-monitoring"
  system_url  = "${var.system_host}/health"
  compute_url = "${var.compute_host}/compute/health"
  cron_name   = "yuki-system-monitoring"
  image       = "406122784773.dkr.ecr.us-east-1.amazonaws.com/system-monitoring-job:0.0.3"
  namespace   = var.namespace
  redis_host  = var.elastic_cache_endpoint_url
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_enabled_proxy_service" {
  source = "./modules/service"

  namespace = var.namespace
  app_group = var.app_group
  app_name  = local.enabled_proxy
  app_port  = var.app_port
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_disabled_proxy_service" {
  source = "./modules/service"

  namespace = var.namespace
  app_group = var.app_group
  app_name  = local.disabled_proxy
  app_port  = var.app_port
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_enabled_proxy_deployment" {
  source = "./modules/deployment"

  namespace                   = var.namespace
  app_group                   = var.app_group
  app_name                    = local.enabled_proxy
  app_port                    = var.app_port
  container_image             = var.container_image
  deployment_replicas         = var.deployment_replicas
  proxy_enabled               = "true"
  proxy_environment_variables = var.proxy_environment_variables
  elastic_cache_endpoint      = var.elastic_cache_endpoint_url
  redis_key_name              = "enb-redis-encryption-key"

  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_disabled_proxy_deployment" {
  source = "./modules/deployment"

  namespace                   = var.namespace
  app_group                   = var.app_group
  app_name                    = local.disabled_proxy
  app_port                    = var.app_port
  container_image             = var.container_image
  deployment_replicas         = var.deployment_replicas
  proxy_enabled               = "false"
  proxy_environment_variables = var.proxy_environment_variables
  elastic_cache_endpoint      = var.elastic_cache_endpoint_url
  redis_key_name              = "dis-redis-encryption-key"
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_proxy_private_alb" {
  source             = "./modules/alb"
  count              = var.create_private_load_balancer ? 1 : 0
  internal           = true
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  app_name           = local.nginx_proxy
  app_port           = local.nginx_port
  namespace          = var.namespace
  load_balancer_name = var.load_balancer_name
  certificate_arn    = var.private_certificate_arn
  path               = var.path
  depends_on = [kubernetes_namespace.namespace, module.nginx_proxy]
}

module "yuki_proxy_public_alb" {
  source             = "./modules/alb"
  count              = var.create_public_load_balancer ? 1 : 0
  internal           = false
  vpc_id             = var.vpc_id
  subnet_ids         = var.public_subnet_ids
  app_name           = local.nginx_proxy
  app_port           = local.nginx_port
  namespace          = var.namespace
  load_balancer_name = var.load_balancer_name
  certificate_arn    = var.public_certificate_arn
  path               = var.path
  depends_on = [kubernetes_namespace.namespace, module.nginx_proxy]
}

module "yuki_proxy_private_link" {
  source = "./modules/nlb"
  count = var.create_private_link ? 1 : 0
  namespace = var.namespace
  app_name = local.nginx_proxy
  app_port = local.nginx_port
  aws_account_id = var.aws_account_id
  load_balancer_name = var.load_balancer_name
  subnet_ids = var.private_subnet_ids
  vpc_id = var.vpc_id
  vpc_cidr = var.vpc_cidr
  depends_on = [kubernetes_namespace.namespace, module.nginx_proxy]
}

module "yuki_enabled_proxy_hpa" {
  source                 = "./modules/hpa"
  min_replicas           = 5
  max_replicas           = 200
  target_cpu_utilization = 30
  namespace              = var.namespace
  app_name               = local.enabled_proxy
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_disabled_proxy_hpa" {
  source                 = "./modules/hpa"
  min_replicas           = 5
  max_replicas           = 30
  target_cpu_utilization = 50
  namespace              = var.namespace
  app_name               = local.disabled_proxy
  depends_on = [kubernetes_namespace.namespace]
}