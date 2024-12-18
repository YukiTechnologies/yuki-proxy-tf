terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.15.0"
  
  name = var.vpc_config.name
  cidr = var.vpc_config.cidr
  azs = var.vpc_config.azs
  private_subnets = var.vpc_config.private_subnets
  public_subnets  = var.vpc_config.public_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Terraform   = "true"
    Environment = "prd"
    OwnedBy = "yuki-proxy"
  }
}