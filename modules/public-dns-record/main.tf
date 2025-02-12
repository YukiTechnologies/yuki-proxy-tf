terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_route53_zone" "public_zone" {
  name = var.public_domain.route53_zone
}

data "aws_lb" "enabled_alb" {
  name = var.public_domain.load_balancer_name
}


resource "aws_route53_record" "primary_dns_record" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = var.public_domain.domain_name
  type    = "A"

  alias {
    name                   = data.aws_lb.enabled_alb.dns_name
    zone_id                = data.aws_lb.enabled_alb.zone_id
    evaluate_target_health = true
  }
}