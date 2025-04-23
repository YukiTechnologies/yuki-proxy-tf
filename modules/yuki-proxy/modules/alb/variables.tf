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

variable "load_balancer_name" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "path" {
  type = string
}

variable "internal" {
  type = bool
}
