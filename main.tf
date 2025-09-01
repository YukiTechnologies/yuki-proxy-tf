module "vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.default
  }
  vpc_config = var.vpc_config
  tags       = var.tags
}

module "eks" {
  source = "./modules/eks-cluster"
  providers = {
    aws = aws.default
  }
  cluster_name       = var.eks_cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnets
  shared_secrets_tag = var.shared_secrets_tag
  tags               = var.tags
  eks_nodes          = var.eks_nodes
  depends_on = [module.vpc]
}

module "aws_alb_controller" {
  source = "./modules/aws-alb-controller"

  main_region                        = var.aws.region
  profile                            = var.aws.profile
  cluster_name                       = var.eks_cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  vpc_id                             = module.vpc.vpc_id
  oidc_provider_arn                  = module.eks.oidc_provider_arn
  node_group                         = module.eks.eks_managed_node_groups
}

module "ingress_class" {
  source = "./modules/ingress-class"

  ingress_class_name = var.ingress_class_name
  cluster_name       = var.eks_cluster_name
  providers = {
    aws        = aws.default
    kubernetes = kubernetes.static
    helm       = helm.static
  }
  depends_on = [module.aws_alb_controller]
}

module "elasticache" {
  source = "./modules/elasticache"
  providers = {
    aws = aws.default
  }
  private_subnets_ids = module.vpc.private_subnets
  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = module.vpc.vpc_cidr_block
  node_type           = var.elasticache_node_type
  tags                = var.tags
}

module "elastic_cache" {
  source = "./modules/elastic-cache"
  providers = {
    aws = aws.default
  }
  private_subnets_ids = module.vpc.private_subnets
  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = module.vpc.vpc_cidr_block
  node_type           = var.elastic_cache_node_type
  tags                = var.tags
}

locals {
  private_proxy_alb = "yuki"
}

module "yuki_proxy" {
  source = "./modules/yuki-proxy"
  providers = {
    aws        = aws.default
    kubernetes = kubernetes.static
    helm       = helm.static
    kubectl    = kubectl
  }
  vpc_id                       = module.vpc.vpc_id
  vpc_cidr                     = var.vpc_config.cidr
  private_subnet_ids           = module.vpc.private_subnets
  public_subnet_ids            = module.vpc.public_subnets
  namespace                    = "yuki-proxy"
  load_balancer_name           = local.private_proxy_alb
  private_link_config          = var.private_link_config
  create_private_load_balancer = var.create_vpc_peering
  create_public_load_balancer  = var.public_domain != null
  private_certificate_arn      = var.client_vpc_config.certificate_arn
  public_certificate_arn       = var.public_domain != null ? var.public_domain.certificate_arn : null
  container_image              = var.container_image
  proxy_environment_variables  = var.proxy_environment_variables
  elasticache_endpoint_url     = module.elasticache.endpoint_url
  system_host                  = var.proxy_environment_variables.SYSTEM_HOST
  compute_host                 = var.proxy_environment_variables.COMPUTE_HOST
  proxy_min_replicas           = var.proxy_min_replicas
  proxy_max_replicas           = var.proxy_max_replicas
  depends_on = [module.ingress_class, module.elasticache, module.eks]
}

module "data_dog" {
  source       = "./modules/data-dog-agent"
  cluster_name = var.eks_cluster_name
  dd_api_key   = var.dd_api_key
  providers = {
    aws        = aws.default
    kubernetes = kubernetes.static
    helm       = helm.static
  }
  depends_on = [module.yuki_proxy]
}

module "yuki_vpc_peering" {
  count  = var.create_vpc_peering ? 1 : 0
  source = "./modules/vpc-peering"
  providers = {
    aws = aws.default
  }
  client_vpc_config                  = var.client_vpc_config
  yuki_vpc_id                        = module.vpc.vpc_id
  yuki_vpc_cidr                      = module.vpc.vpc_cidr_block
  yuki_vpc_azs                       = var.vpc_config.azs
  yuki_vpc_default_security_group_id = module.vpc.vpc_default_security_group_id
  yuki_vpc_private_route_table_ids   = module.vpc.private_route_table_ids
  yuki_vpc_public_route_table_ids    = module.vpc.public_route_table_ids
  yuki_vpc_main_route_table_ids      = module.vpc.main_route_table_id
  tags                               = var.tags
  depends_on = [module.vpc]
}

module "private_dns_record" {
  count  = var.create_vpc_peering ? 1 : 0
  source = "./modules/private-dns-record"
  providers = {
    aws = aws.default
  }
  private_domain = {
    domain_name            = var.client_vpc_config.private_domain_name
    route53_zone_id        = module.yuki_vpc_peering[0].private_zone_id
    load_balancer_dns_name = module.yuki_proxy.private_alb_dns_name
    load_balancer_zone_id  = module.yuki_proxy.private_alb_zone_id
  }
}

module "public_dns_record" {
  source = "./modules/public-dns-record"
  providers = {
    aws = aws.default
  }
  count = var.public_domain != null ? 1 : 0

  public_domain = count.index == 0 ? {
    domain_name            = var.public_domain.name
    route53_zone_id        = var.public_domain.route53_zone_id
    load_balancer_dns_name = module.yuki_proxy.public_alb_dns_name
    load_balancer_zone_id  = module.yuki_proxy.public_alb_zone_id
  } : null
}
