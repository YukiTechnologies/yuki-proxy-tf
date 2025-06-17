terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name               = var.load_balancer_name
  load_balancer_type = "network"
  internal           = true

  vpc_id             = var.vpc_id
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = true

  target_groups = [
    {
      name             = "${var.app_name}-tg"
      backend_protocol = "TCP"
      backend_port     = var.app_port
      target_type      = "ip"
      vpc_id           = var.vpc_id
      health_check = {
        enabled             = true
        port                = var.app_port
        protocol            = "TCP"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "TLS"
      certificate_arn    = var.certificate_arn
      target_group_index = 0
    }
  ]
}

resource "aws_vpc_endpoint_service" "service" {
  acceptance_required        = false
  network_load_balancer_arns = [module.nlb.lb_arn]
  supported_regions = var.private_link_config.supported_regions
  tags = {
    Name = "${var.app_name}-endpoint-service"
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "same_account" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.service.id
  principal_arn           = "arn:aws:iam::${var.private_link_config.aws_account_id}:root"
}

resource "kubernetes_manifest" "private_target_group_binding" {
  provider = kubernetes
  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "${var.app_name}-tgb"
      namespace = var.namespace
    }
    spec = {
      serviceRef = {
        name = var.app_name
        port = var.app_port
      }
      targetGroupARN = module.nlb.target_group_arns[0]
      targetType     = "ip"

      networking = {
        ingress = [
          {
            from = [
              {
                ipBlock = {
                  cidr = var.vpc_cidr
                }
              }
            ]
            ports = [
              {
                port     = var.app_port
                protocol = "TCP"
              }
            ]
          }
        ]
      }
    }
  }
}
