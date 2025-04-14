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
  system_url  = "https://prod.yukicomputing.com/health"
  compute_url = "https://prod.yukicomputing.com/compute/health"
  cron_name   = "yuki-system-monitoring"
  image       = "406122784773.dkr.ecr.us-east-1.amazonaws.com/system-monitoring-job:0.0.3"
  namespace   = var.namespace
  redis_host  = var.elastic_cache_endpoint_url
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_proxy_ingress" {
  source = "./modules/ingress"

  app_name                      = local.nginx_proxy
  app_port                      = local.nginx_port
  namespace                     = var.namespace
  create_private_load_balancers = var.create_private_load_balancers
  load_balancer_name            = var.load_balancer_name
  private_certificate_arn       = var.private_certificate_arn
  public_certificate_arn        = var.public_certificate_arn
  ingress_class_name            = var.ingress_class_name
  ingress_name                  = var.ingress_name
  path                          = var.path

  depends_on = [kubernetes_namespace.namespace, module.nginx_proxy]
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

module "yuki_enabled_proxy_hpa" {
  source                 = "./modules/hpa"
  min_replicas           = 5
  max_replicas           = 30
  target_cpu_utilization = 30
  namespace              = var.namespace
  app_name               = local.enabled_proxy
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_disabled_proxy_hpa" {
  source                 = "./modules/hpa"
  min_replicas           = 5
  max_replicas           = 10
  target_cpu_utilization = 50
  namespace              = var.namespace
  app_name               = local.disabled_proxy
  depends_on = [kubernetes_namespace.namespace]
}

module "nginx_proxy_hpa" {
  source = "./modules/hpa"

  min_replicas           = 5
  max_replicas           = 10
  target_cpu_utilization = 50
  namespace              = var.namespace
  app_name               = local.nginx_proxy
  depends_on = [kubernetes_namespace.namespace]
}