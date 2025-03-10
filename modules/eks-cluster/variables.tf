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
