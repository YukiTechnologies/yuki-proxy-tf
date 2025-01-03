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

module "service_account" {
  source = "./modules/service-account"

  namespace            = var.namespace
  oidc_provider_arn    = var.oidc_provider_arn
  role_name            = "${var.namespace}-dns-role"
  service_account_name = "${var.namespace}-dns-sa"
  depends_on = [kubernetes_namespace.namespace]
}

module "yuki_proxy_ingress" {
  source = "./modules/ingress"

  app_name            = var.app_name
  app_port            = var.app_port
  namespace           = var.namespace
  private_domain_name = var.private_domain_name
  public_domain       = var.public_domain
  create_private_load_balancers = var.create_private_load_balancers
  load_balancer_name  = var.load_balancer_name
  certificate_arn     = var.certificate_arn
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