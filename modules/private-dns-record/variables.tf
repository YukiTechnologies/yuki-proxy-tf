variable "private_domain" {
  type = object({
    domain_name     = string
    route53_zone    = string
    load_balancer_name = string
  })
}