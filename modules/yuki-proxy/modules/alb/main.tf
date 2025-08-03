terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.81.0, < 6.0.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

locals {
  type = var.internal ? "private" : "public"
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-${local.type}-alb-sg"
  description = "Security group for ALB allowing HTTP and HTTPS traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"
  
  name = "${var.load_balancer_name}-${local.type}"

  load_balancer_type = "application"
  internal           = var.internal
  vpc_id             = var.vpc_id
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      action_type        = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  target_groups = [
    {
      name             = "${var.app_name}-${local.type}-tg"
      backend_protocol = "HTTP"
      backend_port     = var.app_port
      target_type      = "ip"
      health_check = {
        enabled             = true
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 15
        matcher             = "200"
      }
    }
  ]
}

resource "kubectl_manifest" "private_target_group_binding" {
  yaml_body = templatefile("${path.module}/target_group_binding.yaml.tftpl", {
    app_name          = var.app_name
    type              = local.type
    namespace         = var.namespace
    app_port          = var.app_port
    target_group_arn  = module.alb.target_group_arns[0]
    security_group_id = aws_security_group.alb_sg.id
  })
}