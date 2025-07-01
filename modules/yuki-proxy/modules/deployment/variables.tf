variable "namespace" {
  type = string
}

variable "app_group" {
  type = string
}

variable "app_name" {
  type = string
}

variable "app_port" {
  type = string
}

variable "deployment_replicas" {
  type = string
}

variable "container_image" {
  type = string
}

variable "proxy_enabled" {
  type = string
}

variable "proxy_environment_variables" {
  type        = map(string)
}

variable "elasticache_endpoint" {
  type = string
}

variable "redis_key_name" {
  type = string
}