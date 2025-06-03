terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_security_group" "elastic_cache_sg" {
  name        = "yuki-proxy-elastic-sg"
  description = "Security group for yuki-proxy ElastiCache cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all traffic from within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_elasticache_subnet_group" "elastic_cache_subnet_group" {
  name       = "yuki-proxy-elastic-group"
  subnet_ids = var.private_subnets_ids

  tags = var.tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "yuki-proxy-redis"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.elastic_cache_subnet_group.name
  
  security_group_ids = [aws_security_group.elastic_cache_sg.id]

  tags = var.tags
}
