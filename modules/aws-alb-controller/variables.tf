variable "profile" {
  type = string
}

variable "main_region" {
  type    = string
}

variable "env_name" {
  type    = string
  default = "proxy"
}

variable "cluster_name" {
  type    = string
}

variable "vpc_id" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_certificate_authority_data" {
  type = string
}

variable "node_group" {
  type = map(any)
}