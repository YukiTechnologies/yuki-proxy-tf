variable "aws" {
  type = object({
    profile = string
    region = string
  })
  default = {
    profile = "default"
    region = "us-east-1"
  }
}

variable "vpc_config" {
  type = object({
    name            = string
    azs             = list(string)
    cidr            = string
    private_subnets = list(string)
    public_subnets  = list(string)
  })
  default = {
    name            = "yuki-proxy-vpc"
    azs             = ["us-east-1a", "us-east-1b"]
    cidr            = "192.168.0.0/16"
    private_subnets = ["192.168.64.0/19", "192.168.96.0/19"]
    public_subnets  = ["192.168.0.0/19", "192.168.32.0/19"]
  }
}

variable "create_vpc_peering" {
  type = bool
  default = false
}

variable "client_vpc_config" {
  type = object({
    id = string
    cidr_blocks = list(string)
    route_53_zone_name = string
    route_table_ids = list(string)
    private_domain_name = string
    certificate_arn = string
  })
  default = {
    id = "vpc-1"
    cidr_blocks = ["10.0.0.0/16"]
    route_53_zone_name = "private.example.com"
    route_table_ids = [""]
    private_domain_name = "private.example.com"
    certificate_arn = ""
  }
}

variable "eks_cluster_name" {
  default = "yuki-proxy"
}

variable "ingress_class_name" {
  type = string
  default = "yuki-proxy-ingress-class"
}

variable "container_image" {
  type = string
  default = ""
}

variable "dd_api_key" {
  type = string
  default = ""
}

variable "public_domain" {
  type = object({
    name = string
    route53_zone_id = string
    certificate_arn = string
  })
  default = null
}

variable "proxy_environment_variables" {
  description = "Environment variables for proxy deployment"
  type        = map(string)
  default     = {
    PROXY_HOST   = ""
    COMPUTE_HOST = "https://prod.yukicomputing.com"
    SYSTEM_HOST  = "https://prod.yukicomputing.com"
    COMPANY_GUID = ""
    ORG_GUID     = ""
    ACCOUNT_GUID = ""
  }
}

variable "shared_secrets_tag" {
  type = object({
    key = string
    value = string
  })
  default = {
    key = "Acceess"
    value = "YukiProxy"
  }
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
  default     = {
    Env       = "prd"
    Terraform = "true"
    OwnedBy   = "yuki-proxy"
  }
}

variable "private_link_config" {
  type = object({
    aws_account_id = string
    supported_regions = list(string)
  })
  default = null
}

variable "proxy_min_replicas" {
  type = number
  default = 20
}

variable "proxy_max_replicas" {
  type = number
  default = 100
}

variable "eks_nodes" {
  type = object({
    min_size =number
    desired_size = number
    max_size = number
  })
  default = {
    min_size = 2
    desired_size = 2
    max_size = 10
  }
}

variable "elastic_cache_node_type" {
  type    = string
  default = "cache.r6g.2xlarge"
}

variable "elasticache_node_type" {
  type = string
  default = "cache.m7g.large"
}