variable "vpc_config" {
  type = object({
    name            = string
    azs             = list(string)
    cidr            = string
    private_subnets = list(string)
    public_subnets  = list(string)
  })
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
}