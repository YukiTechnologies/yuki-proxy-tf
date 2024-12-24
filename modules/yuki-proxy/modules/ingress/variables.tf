variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "app_port" {
  type = string
}

variable "ingress_class_name" {
  type = string
}

variable "ingress_name" {
  type = string
}

variable "load_balancer_name" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "path" {
  type = string
}

variable "create_private_load_balancers" {
  type = bool
}

variable "public_domain" {
  type = object({
    name = string
    identifier = string
    type = string
    health_check_id = string
  })
}

variable "private_domain_name" {
  type = string
}
