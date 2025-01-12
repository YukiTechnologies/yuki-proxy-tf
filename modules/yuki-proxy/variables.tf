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
  type        = map(string)
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

variable "proxy_enabled" {
  type = string
}

variable "app_group" {
  type = string
  default = "default-app-group"
}

variable "app_name" {
  type = string
  default = "yuki-proxy"
}

variable "app_port" {
  type = string
  default = "5162"
}

variable "deployment_replicas" {
  type = string
  default = "5"
}

variable "path" {
  type = string
  default = "/"
}

variable "elastic_cache_endpoint_url" {
  type = string
}

variable "create_private_load_balancers" {
  type = bool
}