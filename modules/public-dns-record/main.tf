terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.81.0, < 6.0.0"
    }
  }
}

resource "aws_route53_record" "primary_dns_record" {
  zone_id = var.public_domain.route53_zone_id
  name    = var.public_domain.domain_name
  type    = "A"

  alias {
    name                   = var.public_domain.load_balancer_dns_name
    zone_id                = var.public_domain.load_balancer_zone_id
    evaluate_target_health = true
  }
}