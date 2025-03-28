terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_route53_zone" "private_zone" {
  name = var.private_domain.route53_zone
  private_zone  = true
}

data "aws_lb" "private_alb" {
  name = var.private_domain.load_balancer_name
}

resource "aws_route53_record" "alb_dns_record" {
  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = var.private_domain.domain_name
  type    = "A"

  alias {
    name                   = data.aws_lb.private_alb.dns_name
    zone_id                = data.aws_lb.private_alb.zone_id
    evaluate_target_health = true
  }
}
