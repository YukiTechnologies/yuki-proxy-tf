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
  nginx_proxy         = "nginx-proxy"
  enabled_proxy_name  = "yuki-proxy-enabled"
  disabled_proxy_name = "yuki-proxy-disabled"
  nginx_port          = "80"
}

module "nginx_proxy" {
  source = "./modules/nginx-proxy"
  namespace    = var.namespace
  service_name = local.nginx_proxy
  proxy_disabled = {
    host = local.enabled_proxy_name
    port = var.app_port
  }
  proxy_enabled = {
    host = local.disabled_proxy_name
    port = var.app_port
  }
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
  app_name  = local.enabled_proxy_name
  app_port  = var.app_port
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_disabled_proxy_service" {
  source = "./modules/service"

  namespace = var.namespace
  app_group = var.app_group
  app_name  = local.disabled_proxy_name
  app_port  = var.app_port
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_enabled_proxy_deployment" {
  source = "./modules/deployment"

  namespace                   = var.namespace
  app_group                   = var.app_group
  app_name                    = local.enabled_proxy_name
  app_port                    = var.app_port
  container_image             = var.container_image
  deployment_replicas         = var.deployment_replicas
  proxy_enabled               = "true"
  proxy_environment_variables = var.proxy_environment_variables
  elastic_cache_endpoint      = var.elastic_cache_endpoint_url

  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_disabled_proxy_deployment" {
  source = "./modules/deployment"

  namespace                   = var.namespace
  app_group                   = var.app_group
  app_name                    = local.disabled_proxy_name
  app_port                    = var.app_port
  container_image             = var.container_image
  deployment_replicas         = var.deployment_replicas
  proxy_enabled               = "false"
  proxy_environment_variables = var.proxy_environment_variables
  elastic_cache_endpoint      = var.elastic_cache_endpoint_url

  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_enabled_proxy_hpa" {
  source = "./modules/hpa"

  namespace = var.namespace
  app_name  = local.enabled_proxy_name
  depends_on = [kubernetes_namespace.namespace]
}