variable "container_image" {
  type = string
}

variable "public_certificate_arn" {
  type = string
}

variable "private_certificate_arn" {
  type = string
}

variable "ingress_class_name" {
  type = string
}

variable "proxy_environment_variables" {
  type = map(string)
}

variable "namespace" {
  type = string
}

variable "load_balancer_name" {
  type = string
}

variable "ingress_name" {
  type = string
}

variable "app_group" {
  type    = string
  default = "default-app-group"
}

variable "app_port" {
  type    = string
  default = "5162"
}

variable "deployment_replicas" {
  type    = string
  default = "5"
}

variable "path" {
  type    = string
  default = "/"
}

variable "elastic_cache_endpoint_url" {
  type = string
}

variable "create_private_load_balancer" {
  type = bool
}

variable "create_public_load_balancer" {
  type = bool
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "compute_host" {
  type = string
}

variable "system_host" {
  type = string
}

variable "private_link_config" {
  type = object({
    aws_account_id = string
    supported_regions = list(string)
  })
}