variable "vpc_id" {
  type        = string
}

variable "private_subnets" {
  type        = list(any)
}

variable "cluster_name" {
  type = string
}

variable "shared_secrets_tag" {
  type = object({
    key = string
    value = string
  })
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
}

variable "eks_nodes" {
  type = object({
    min_size     = number
    desired_size = number
    max_size     = number
  })
}
