variable "vpc_config" {
  type = object({
    name            = string
    azs             = list(string)
    cidr            = string
    private_subnets = list(string)
    public_subnets  = list(string)
  })
}
