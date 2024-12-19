terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_elasticache_subnet_group" "elastic_cache_subnet_group" {
  name       = "yuki-proxy-elastic-group"
  subnet_ids = var.private_subnets_ids

  tags = {
    Name = "yuki-proxy-elastic-group"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "yuki-proxy-redis"
  engine               = "redis"
  node_type            = "cache.t4g.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.elastic_cache_subnet_group.name
  security_group_ids   = [var.security_group]

  tags = {
    Name = "yuki-proxy-redis"
    OwnedBy = "yuki-proxy"
  }
}