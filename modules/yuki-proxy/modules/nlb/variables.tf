variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "app_port" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "load_balancer_name" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "private_link_config" {
  type = object({
    aws_account_id = string
    supported_regions = list(string)
  })
}