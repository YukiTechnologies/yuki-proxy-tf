variable "source_cluster_id" {
  description = "The ID of the non-cluster Redis ElastiCache instance"
}

variable "destination_cluster_id" {
  description = "The ID of the cluster-mode ElastiCache instance"
}

variable "destination_cluster_sg_id" {
  description = "The security group ID of the destination cluster"
}

variable "instance_type" {
  description = "EC2 instance type for Redis-Shake runner"
  type        = string
  default     = "t3.medium"
}