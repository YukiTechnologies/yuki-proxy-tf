output "ingress_load_balancer_hostname" {
  value = kubernetes_ingress_v1.ingress.status.0.load_balancer.0
}

output "internet_load_balancer_hostname" {
  value = kubernetes_ingress_v1.internet_ingress.status.0.load_balancer.0
}