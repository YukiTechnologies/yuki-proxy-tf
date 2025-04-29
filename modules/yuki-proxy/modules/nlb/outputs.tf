output "nlb_dns_name" {
  value = module.nlb.lb_dns_name
}
output "nlb_zone_id" {
  value = module.nlb.lb_zone_id
}

output "endpoint_service_name" {
  value = aws_vpc_endpoint_service.service.service_name
}