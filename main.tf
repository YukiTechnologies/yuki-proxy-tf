module "vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.default
  }
  vpc_config = var.vpc_config
}

module "eks" {
  source = "./modules/eks-cluster"
  providers = {
    aws = aws.default
  }
  cluster_name      = var.eks_cluster_name
  vpc_id            = module.vpc.vpc_id
  private_subnets   = module.vpc.private_subnets
  depends_on = [module.vpc]
}

module "aws_alb_controller" {
  source = "./modules/aws-alb-controller"

  main_region       = var.aws.region
  profile           = var.aws.profile
  cluster_name      = var.eks_cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  node_group        = module.eks.eks_managed_node_groups
}

module "ingress_class" {
  source = "./modules/ingress-class"

  ingress_class_name = var.ingress_class_name
  providers = {
    aws = aws.default
    kubernetes = kubernetes.static
    helm = helm.static
  }
  depends_on = [module.aws_alb_controller]
}

module "elastic_cache" {
  source = "./modules/elastic-cache"
  providers = {
    aws = aws.default
  }
  private_subnets_ids   = module.vpc.private_subnets
  security_group        = module.vpc.vpc_default_security_group_id
}

module "yuki_proxy_enabled" {
  source = "./modules/yuki-proxy"

  namespace = "yuki-proxy-enabled"
  load_balancer_name = "enab-yuki-proxy-lb"
  ingress_name = "enab-yuki-proxy-ingress"
  create_private_load_balancers = var.create_vpc_peering
  container_image             = var.container_image
  certificate_arn             = var.certificate_arn
  ingress_class_name          = var.ingress_class_name
  proxy_environment_variables = var.proxy_environment_variables
  proxy_enabled = "true"
  providers = {
    aws = aws.default
    kubernetes = kubernetes.static
    helm = helm.static
  }
  elastic_cache_endpoint_url = module.elastic_cache.endpoint_url
  depends_on = [module.ingress_class, module.elastic_cache]
}

module "yuki_proxy_disabled" {
  source = "./modules/yuki-proxy"

  namespace = "yuki-proxy-disabled"
  load_balancer_name = "dis-yuki-proxy-lb"
  ingress_name = "dis-yuki-proxy-ingress"
  create_private_load_balancers = false
  container_image             = var.container_image
  certificate_arn             = var.certificate_arn
  ingress_class_name          = var.ingress_class_name
  proxy_environment_variables = var.proxy_environment_variables
  proxy_enabled = "false"
  providers = {
    aws = aws.default
    kubernetes = kubernetes.static
    helm = helm.static
  }
  elastic_cache_endpoint_url = module.elastic_cache.endpoint_url
  depends_on = [module.ingress_class, module.elastic_cache]
}

module "data_dog" {
  source = "./modules/data-dog-agent"
  cluster_name = var.eks_cluster_name
  dd_api_key = var.dd_api_key
  providers = {
    aws = aws.default
    kubernetes = kubernetes.static
    helm = helm.static
  }
  depends_on = [module.yuki_proxy_enabled,module.yuki_proxy_disabled]
}

module "yuki_vpc_peering" {
  count = var.create_vpc_peering ? 1 : 0
  source = "./modules/vpc-peering"
  providers = {
    aws = aws.default
  }
  client_vpc_config                     = var.client_vpc_config
  yuki_vpc_id                           = module.vpc.vpc_id
  yuki_vpc_cidr                         = module.vpc.vpc_cidr_block
  yuki_vpc_azs                          = var.vpc_config.azs 
  yuki_vpc_default_security_group_id    = module.vpc.vpc_default_security_group_id
  yuki_vpc_private_route_table_ids      = module.vpc.private_route_table_ids
  yuki_vpc_public_route_table_ids       = module.vpc.public_route_table_ids
  yuki_vpc_main_route_table_ids         = module.vpc.main_route_table_id
  depends_on = [module.vpc]
}
