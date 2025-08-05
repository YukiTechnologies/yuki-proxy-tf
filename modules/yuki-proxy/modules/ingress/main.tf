resource "kubernetes_ingress_v1" "ingress" {
  count = var.create_private_load_balancers ? 1 : 0
  wait_for_load_balancer = true
  metadata {
    name        = var.ingress_name
    namespace   = var.namespace
    annotations = {
      "alb.ingress.kubernetes.io/load-balancer-name" : var.load_balancer_name
      "alb.ingress.kubernetes.io/scheme" : "internal"
      "alb.ingress.kubernetes.io/listen-ports" : "[{\"HTTPS\":443}, {\"HTTP\":80}]"
      "alb.ingress.kubernetes.io/certificate-arn" : var.private_certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect" : "443"
      "alb.ingress.kubernetes.io/healthcheck-protocol" : "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" : "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-path" : "/health"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" : "15"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" : "5"
      "alb.ingress.kubernetes.io/success-codes" : "200"
      "alb.ingress.kubernetes.io/healthy-threshold-count" : "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" : "2"
      "alb.ingress.kubernetes.io/tags" : "Environment=prod,OwnedBy=yuki-proxy"
    }
  }

    #? alb.ingress.kubernetes.io/scheme: internet-facing

    #   alb.ingress.kubernetes.io/load-balancer-name: prd-load-balancer
    #   alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    #   alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:eu-west-1:406122784773:certificate/a6416c9e-922d-4833-9c2c-0a1edb7f0ea9
    #   alb.ingress.kubernetes.io/ssl-redirect: '443'
    #   alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    #   alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    #   alb.ingress.kubernetes.io/healthcheck-path: /health
    #   alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    #   alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    #   alb.ingress.kubernetes.io/success-codes: '200'
    #   alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    #   alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'

  spec {
    ingress_class_name = var.ingress_class_name
    rule {
      http {
        path {
          path = var.path
          path_type = "Prefix"
          backend {
            service {
              name = var.app_name
              port {
                number = var.app_port
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "internet_ingress" {
  count = var.create_public_load_balancers ? 1 : 0
  wait_for_load_balancer = true
  metadata {
    name        = "pub-${var.ingress_name}"
    namespace   = var.namespace
    annotations = {
      "alb.ingress.kubernetes.io/load-balancer-name" : "pub${var.load_balancer_name}"
      "alb.ingress.kubernetes.io/scheme" : "internet-facing"
      "alb.ingress.kubernetes.io/listen-ports" : "[{\"HTTPS\":443}, {\"HTTP\":80}]"
      "alb.ingress.kubernetes.io/certificate-arn" : var.public_certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect" : "443"
      "alb.ingress.kubernetes.io/healthcheck-protocol" : "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" : "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-path" : "/health"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" : "15"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" : "5"
      "alb.ingress.kubernetes.io/success-codes" : "200"
      "alb.ingress.kubernetes.io/healthy-threshold-count" : "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" : "2"
      "alb.ingress.kubernetes.io/tags" : "Environment=prod,OwnedBy=yuki-proxy"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name
    rule {
      http {
        path {
          path = var.path
          path_type = "Prefix"
          backend {
            service {
              name = var.app_name
              port {
                number = var.app_port
              }
            }
          }
        }
      }
    }
  }
}
