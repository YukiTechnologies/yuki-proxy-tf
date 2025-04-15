output "yuki_proxy_public_load_balancer_dns" {
  description = "The DNS name of the Yuki Proxy load balancer"
  value       = kubernetes_ingress_v1.internet_ingress.status[0].load_balancer[0].ingress[0].hostname
}

output "yuki_proxy_private_load_balancer_dns" {
  description = "The DNS name of the Yuki Proxy load balancer"
  value       = var.create_private_load_balancers ? kubernetes_ingress_v1.ingress[0].status[0].load_balancer[0].ingress[0].hostname : null
}