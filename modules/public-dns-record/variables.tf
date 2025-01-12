variable "public_domain" {
  type = object({
    domain_name     = string
    route53_zone    = string
    enabale_load_balancer_name = string
    disabled_load_balancer_name = string
  })
}