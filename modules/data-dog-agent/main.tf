terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.81.0"
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

resource "helm_release" "datadog_agent" {
  name       = "datadog-agent"
  chart      = "datadog"
  repository = "https://helm.datadoghq.com"
  version    = "3.81.1"

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.dd_api_key
  }

  set {
    name  = "datadog.clusterName"
    value = var.cluster_name
  }
  
  set {
    name  = "datadog.containerExcludeLogs"
    value = "kube_namespace:kube-system kube_namespace:default kube_namespace:kube-node-lease kube_namespace:kube-public"
  }

  set {
    name  = "datadog.logs.enabled"
    value = true
  }

  set {
    name  = "datadog.logs.containerCollectAll"
    value = true
  }

  set {
    name  = "datadog.leaderElection"
    value = true
  }

  set {
    name  = "datadog.collectEvents"
    value = true
  }

  set {
    name  = "clusterAgent.enabled"
    value = true
  }

  set {
    name  = "datadog.kubeStateMetricsEnabled"
    value = "true"
  }

  set {
    name  = "datadog.kubeStateMetricsCore.enabled"
    value = "true"
  }

  set {
    name  = "datadog.metrics.enabled"
    value = "true"
  }
}