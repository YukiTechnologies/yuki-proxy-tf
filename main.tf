module "vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.default
  }
  vpc_config = var.vpc_config
}