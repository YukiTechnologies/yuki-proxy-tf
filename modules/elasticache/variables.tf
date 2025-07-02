variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnets_ids" {
  type = list(string)
}

variable "cluster_id" {
  type = string
  default = "yuki-proxy-cache-cluster"
}

variable "node_type" {
  description = "Cache node that supports autoscale"
  type        = string
  default     = "cache.m7g.large"
}

variable "tags" {
  description = "Additional tags to apply to the Valkey cluster"
  type = map(string)
  default = {}
}

variable "shards_autoscaling_rules" {
  description = "Shard autoscaling parameters"
  type = map(string)
  default = {
    min_capacity           = 1
    max_capacity           = 10
    predefined_metric_type = "ElastiCacheDatabaseCapacityUsageCountedForEvictPercentage"
    target_value           = 70.0
    scale_in_cooldown      = 300
    scale_out_cooldown     = 300
  }
}

variable "replica_autoscaling_rules" {
  description = "Replica autoscaling parameters"
  type = map(string)
  default = {
    min_capacity           = 1
    max_capacity           = 5
    target_value           = 70.0
    scale_in_cooldown      = 300
    scale_out_cooldown     = 300
  }
}