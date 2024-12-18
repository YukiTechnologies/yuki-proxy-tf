variable "aws" {
  type = object({
    profile = string
    region = string
  })
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