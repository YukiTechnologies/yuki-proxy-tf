variable "vpc_id" {
  type        = string
}

variable "private_subnets" {
  type        = list(any)
}

variable "cluster_name" {
  type = string
}
