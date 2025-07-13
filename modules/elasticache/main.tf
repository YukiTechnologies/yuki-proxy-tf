terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.81.0"
    }
  }
}

locals {
  valkey_tags = merge({
    Name = var.cluster_id
  }, var.tags)

}

resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "yuki-proxy-elasticache-cluster"
  subnet_ids = var.private_subnets_ids

  tags = var.tags
}

resource "aws_security_group" "elasticache_sg" {
  name        = "yuki-proxy-elasticache-sg"
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

resource "aws_elasticache_parameter_group" "valkey_params" {
  name        = "valkey-cluster-mode"
  family      = "valkey8"
  description = "Valkey cluster mode enabled params"

  parameter {
    name  = "cluster-enabled"
    value = "yes"
  }
}

resource "aws_elasticache_replication_group" "valkey_cluster" {
  replication_group_id = var.cluster_id
  description          = "Cluster mode enabled Valkey setup"
  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = var.node_type
  parameter_group_name = aws_elasticache_parameter_group.valkey_params.name
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_subnet_group.name
  security_group_ids = [aws_security_group.elasticache_sg.id]

  port                       = 6379
  multi_az_enabled           = true
  automatic_failover_enabled = true
  transit_encryption_enabled = false
  at_rest_encryption_enabled = true
  tags                       = local.valkey_tags

  num_node_groups         = 2
  replicas_per_node_group = 2

  lifecycle {
    ignore_changes = [num_node_groups, replicas_per_node_group]
  }

  apply_immediately = true
}

resource "aws_appautoscaling_target" "shards" {
  min_capacity       = var.shards_autoscaling_rules.min_capacity
  max_capacity       = var.shards_autoscaling_rules.max_capacity
  resource_id        = "replication-group/${aws_elasticache_replication_group.valkey_cluster.id}"
  scalable_dimension = "elasticache:replication-group:NodeGroups"
  service_namespace  = "elasticache"
}

resource "aws_appautoscaling_policy" "shard_policy" {
  name               = "shards-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.shards.resource_id
  scalable_dimension = aws_appautoscaling_target.shards.scalable_dimension
  service_namespace  = aws_appautoscaling_target.shards.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.shards_autoscaling_rules.predefined_metric_type
    }
    target_value       = var.shards_autoscaling_rules.target_value
    scale_in_cooldown  = var.shards_autoscaling_rules.scale_in_cooldown
    scale_out_cooldown = var.shards_autoscaling_rules.scale_out_cooldown
  }
}

resource "aws_appautoscaling_target" "replicas" {
  min_capacity       = var.replica_autoscaling_rules.min_capacity
  max_capacity       = var.replica_autoscaling_rules.max_capacity
  resource_id        = "replication-group/${aws_elasticache_replication_group.valkey_cluster.id}"
  scalable_dimension = "elasticache:replication-group:Replicas"
  service_namespace  = "elasticache"
}

resource "aws_appautoscaling_policy" "replica_policy" {
  name               = "replicas-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.replicas.resource_id
  scalable_dimension = aws_appautoscaling_target.replicas.scalable_dimension
  service_namespace  = aws_appautoscaling_target.replicas.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ElastiCacheReplicaEngineCPUUtilization"
    }
    target_value       = var.replica_autoscaling_rules.target_value
    scale_in_cooldown  = var.replica_autoscaling_rules.scale_in_cooldown
    scale_out_cooldown = var.replica_autoscaling_rules.scale_out_cooldown
  }
}
