terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
      version = ">= 2.16, < 3.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

data "aws_region" "current" {}

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

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "extraArgs.expander"
    value = "least-waste"
  }
  
  set {
    name  = "extraArgs.ignore-daemonsets-utilization"
    value = "true"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "5m" 
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "5m"
  }
}