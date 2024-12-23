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
  default = true
}

variable "client_vpc_config" {
  type = object({
    id = string
    cidr_blocks = list(string)
    route_53_zone_name = string
    route_table_ids = list(string)
  })
  default = {
    id = "vpc-1"
    cidr_blocks = ["10.0.0.0/16"]
    route_53_zone_name = "isay.yuki-testing.com"
    route_table_ids = [""]
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
  default = "[PROXY_IMAGE]"
}

variable "dd_api_key" {
  type = string
  default = "[DD_API_KEY]"
}

variable "certificate_arn" {
  type = string
  default = ""
}

variable "proxy_environment_variables" {
  description = "Environment variables for proxy deployment"
  type        = map(string)
  default     = {
    PROXY_HOST   = "[PROXY_HOST]"
    COMPUTE_HOST = "https://prod.yukicomputing.com"
    SYSTEM_HOST  = "https://prod.yukicomputing.com"
    COMPANY_GUID = "[COMPANY_GUID]"
    ORG_GUID     = "[ORG_GUID]"
    ACCOUNT_GUID = "[ACCOUNT_GUID]"
  }
}