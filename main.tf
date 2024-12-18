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
