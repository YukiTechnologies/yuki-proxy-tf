output "yuki_vpc_id" {
  value = module.vpc.vpc_id
}

output "private_link_endpoint_service_name" {
  value = module.yuki_proxy.private_link_endpoint_name
}