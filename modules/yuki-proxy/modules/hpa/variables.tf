variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "min_replicas" {
  type    = number
}

variable "max_replicas" {
  type    = number
}

variable "target_cpu_utilization" {
  type    = number
}