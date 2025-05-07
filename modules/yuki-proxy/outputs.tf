output "private_alb_dns_name" {
  value = var.create_private_load_balancer ? module.yuki_proxy_private_alb[0].alb_dns_name : null
}

output "private_alb_zone_id" {
  value = var.create_private_load_balancer ? module.yuki_proxy_private_alb[0].alb_zone_id : null
}


output "public_alb_dns_name" {
  value = var.create_public_load_balancer ? module.yuki_proxy_public_alb[0].alb_dns_name : null
}

output "public_alb_zone_id" {
  value = var.create_public_load_balancer ? module.yuki_proxy_public_alb[0].alb_zone_id : null
}

output "private_link_endpoint_name" {
  value = var.private_link_config != null ? module.yuki_proxy_private_link[0].endpoint_service_name : null
}