terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  split_dns = split("-", var.private_domain.load_balancer_dns_name)
  first_element = length(local.split_dns) > 0 ? local.split_dns[1] : ""
}

data "aws_lb" "private_alb" {
  name = local.first_element
}

resource "aws_route53_record" "alb_dns_record" {
  zone_id = var.private_domain.route53_zone_id
  name    = var.private_domain.domain_name
  type    = "A"

  alias {
    name                   = var.private_domain.load_balancer_dns_name
    zone_id                = data.aws_lb.private_alb.zone_id
    evaluate_target_health = true
  }
}
