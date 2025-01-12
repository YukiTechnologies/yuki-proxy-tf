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

module "yuki_proxy_ingress" {
  source = "./modules/ingress"

  app_name            = var.app_name
  app_port            = var.app_port
  namespace           = var.namespace
  create_private_load_balancers = var.create_private_load_balancers
  load_balancer_name  = var.load_balancer_name
  private_certificate_arn    = var.private_certificate_arn
  public_certificate_arn     = var.public_certificate_arn
  ingress_class_name  = var.ingress_class_name
  ingress_name        = var.ingress_name
  path                = var.path

  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_proxy_service" {
  source = "./modules/service"
  
  namespace = var.namespace
  app_group = var.app_group
  app_name = var.app_name
  app_port = var.app_port
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_proxy_deployment" {
  source = "./modules/deployment"

  namespace           = var.namespace
  app_group           = var.app_group
  app_name            = var.app_name
  app_port            = var.app_port
  container_image     = var.container_image
  deployment_replicas = var.deployment_replicas
  proxy_enabled       = var.proxy_enabled
  proxy_environment_variables = var.proxy_environment_variables
  elastic_cache_endpoint = var.elastic_cache_endpoint_url
  
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_proxy_hpa" {
  source = "./modules/hpa"
  
  namespace = var.namespace
  app_name = var.app_name
  depends_on = [kubernetes_namespace.namespace]
}