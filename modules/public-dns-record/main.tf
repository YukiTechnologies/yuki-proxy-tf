terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_route53_zone" "public_zone" {
  name = var.public_domain.route53_zone
}

data "aws_lb" "public_enabled_lb" {
  name = var.public_domain.enabale_load_balancer_name
}

data "aws_lb" "public_disabled_lb" {
  name = var.public_domain.disabled_load_balancer_name
}

resource "aws_route53_health_check" "primary_lb_health_check" {
  fqdn                          = var.public_domain.domain_name
  type                          = "HTTPS"
  resource_path                 = "/"
  failure_threshold             = 1
  request_interval              = 10
  port                          = 443
}

resource "aws_route53_record" "primary_dns_record" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = var.public_domain.domain_name
  type    = "A"

  alias {
    name                   = data.aws_lb.public_enabled_lb.dns_name
    zone_id                = data.aws_lb.public_enabled_lb.zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
  set_identifier = "primary"
  health_check_id = aws_route53_health_check.primary_lb_health_check.id
}

resource "aws_route53_record" "secondary_dns_record" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = var.public_domain.domain_name
  type    = "A"

  alias {
    name                   = data.aws_lb.public_disabled_lb.dns_name
    zone_id                = data.aws_lb.public_disabled_lb.zone_id
    evaluate_target_health = false
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
  set_identifier = "secondary"
}