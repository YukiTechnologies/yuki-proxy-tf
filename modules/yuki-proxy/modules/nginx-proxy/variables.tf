variable "service_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "proxy_enabled" {
  type = object({
    host = string
    port = string
  })
}

variable "proxy_disabled" {
  type = object({
    host = string
    port = string
  })
}