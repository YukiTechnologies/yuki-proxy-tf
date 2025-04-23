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

resource "kubernetes_manifest" "private_target_group_binding" {
  
  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "${var.app_name}-${local.type}-tgb"
      namespace = var.namespace
    }
    spec = {
      serviceRef = {
        name = var.app_name
        port = var.app_port
      }
      targetGroupARN = module.alb.target_group_arns[0]
      targetType     = "ip"

      networking = {
        ingress = [
          {
            from = [
              {
                securityGroup = {
                  groupID = aws_security_group.alb_sg.id
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
