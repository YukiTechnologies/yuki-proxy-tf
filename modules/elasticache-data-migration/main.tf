terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

data "aws_elasticache_cluster" "source_db" {
  cluster_id = var.source_cluster_id
}

data "aws_elasticache_replication_group" "dest_db" {
  replication_group_id = var.destination_cluster_id
}

data "aws_elasticache_subnet_group" "source_subnet" {
  name = data.aws_elasticache_cluster.source_db.subnet_group_name
}

locals {
  source_db = {
    vpc_id         = data.aws_elasticache_subnet_group.source_subnet.vpc_id
    subnet_id      = tolist(data.aws_elasticache_subnet_group.source_subnet.subnet_ids)[0]
    security_group = tolist(data.aws_elasticache_cluster.source_db.security_group_ids)[0]
    endpoint       = data.aws_elasticache_cluster.source_db.cache_nodes[0].address
  }

  dest_db = {
    security_group = var.destination_cluster_sg_id
    endpoint       = data.aws_elasticache_replication_group.dest_db.configuration_endpoint_address
  }
}

# Fetch ECS‑optimized AMI (with Docker preinstalled)
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_security_group" "shake_sg" {
  name        = "redis_shake_sg"
  description = "Allow outbound and ElastiCache access for Redis-Shake EC2"
  vpc_id      = local.source_db.vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_ec2_to_elasticache_source" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = local.source_db.security_group
  source_security_group_id = aws_security_group.shake_sg.id
  description              = "Allow Redis-Shake EC2 to connect to ElastiCache"
}

resource "aws_security_group_rule" "allow_ec2_to_elasticache_dest" {
  count                    = local.source_db.security_group != local.dest_db.security_group ? 1 : 0
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = local.dest_db.security_group
  source_security_group_id = aws_security_group.shake_sg.id
  description              = "Allow Redis-Shake EC2 to connect to ElastiCache"
}

resource "aws_instance" "shake_runner" {
  ami           = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type
  subnet_id     = local.source_db.subnet_id
  security_groups = [aws_security_group.shake_sg.id]
  user_data = templatefile("${path.module}/setup_userdata.tpl", {
    from_address = local.source_db.endpoint
    to_address   = local.dest_db.endpoint
  })

  tags = { Name = "redis-shake-runner" }

  # Enable CloudWatch console output
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  depends_on = [
    aws_security_group_rule.allow_ec2_to_elasticache_source, aws_security_group_rule.allow_ec2_to_elasticache_dest
  ]
}
