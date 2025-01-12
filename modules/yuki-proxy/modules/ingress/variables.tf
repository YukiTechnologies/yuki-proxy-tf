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

variable "private_certificate_arn" {
  type = string
}

variable "public_certificate_arn" {
  type = string
}

variable "path" {
  type = string
}

variable "create_private_load_balancers" {
  type = bool
}
