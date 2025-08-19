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

variable "target_vpc_id" {
  description = "VPC ID where to run the migration instance (usually destination VPC)"
  type        = string
  default     = null
}

variable "target_subnet_id" {
  description = "Subnet ID where to run the migration instance"
  type        = string
  default     = null
}
