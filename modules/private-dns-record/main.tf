terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_route53_record" "alb_dns_record" {
  zone_id = var.private_domain.route53_zone_id
  name    = var.private_domain.domain_name
  type    = "A"

  alias {
    name                   = var.private_domain.load_balancer_dns_name
    zone_id                = var.private_domain.load_balancer_zone_id
    evaluate_target_health = true
  }
}
