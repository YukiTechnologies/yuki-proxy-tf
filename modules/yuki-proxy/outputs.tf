output "yuki_proxy_public_load_balancer_dns" {
  description = "The DNS name of the Yuki Proxy load balancer"
  value       = module.yuki_proxy_ingress.yuki_proxy_public_load_balancer_dns
}

output "yuki_proxy_private_load_balancer_dns" {
  description = "The DNS name of the Yuki Proxy load balancer"
  value       = module.yuki_proxy_ingress.yuki_proxy_private_load_balancer_dns
}