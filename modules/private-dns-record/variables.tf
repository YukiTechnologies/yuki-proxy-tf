variable "private_domain" {
  type = object({
    domain_name     = string
    route53_zone_id    = string
    load_balancer_dns_name = string
  })
}