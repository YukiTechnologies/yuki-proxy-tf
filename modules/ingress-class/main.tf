terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_ingress_class" "ingress_class" {
  metadata {
    name = var.ingress_class_name
    annotations = {
      "ingressclass.kubernetes.io/is-default-class": "true"
    }
  }

  spec {
    controller = "ingress.k8s.aws/alb"
  }
}