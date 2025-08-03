terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.81.0, < 6.0.0"
    }
  }
}

resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = var.yuki_vpc_id
  peer_vpc_id = var.client_vpc_config.id
  auto_accept = true

  tags = var.tags
}

resource "aws_security_group_rule" "allow_vpc_peering" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.client_vpc_config.cidr_blocks
  security_group_id = var.yuki_vpc_default_security_group_id
}

resource "aws_vpc_peering_connection_options" "requester" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

locals {
  private_azs_to_cidr = merge([
    for index, az in var.yuki_vpc_azs: {
      for cidr in var.client_vpc_config.cidr_blocks:
      "${cidr}-${az}" => {
        cidr   = cidr
        route_table_id = var.yuki_vpc_private_route_table_ids[index]
      }
    }
  ]...)
}

resource "aws_route" "vpc_yuki_private_to_vpc_client" { 
  for_each = local.private_azs_to_cidr
  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "vpc_yuki_public_to_vpc_client" {
  for_each = toset(var.client_vpc_config.cidr_blocks)
  route_table_id            = var.yuki_vpc_public_route_table_ids[0]
  destination_cidr_block    = each.value
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "vpc_yuki_main_to_vpc_client" {
  for_each = toset(var.client_vpc_config.cidr_blocks)
  route_table_id            = var.yuki_vpc_main_route_table_ids
  destination_cidr_block    = each.key
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "vpc_client_to_vpc_yuki" {
  for_each = toset(var.client_vpc_config.route_table_ids)
  route_table_id         = each.value
  destination_cidr_block = var.yuki_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route53_zone" "private" {
  name = var.client_vpc_config.route_53_zone_name
  vpc {
    vpc_id = var.yuki_vpc_id
  }

  vpc {
    vpc_id = var.client_vpc_config.id
  }
  comment = "Private hosted zone for yuki proxy"
}
