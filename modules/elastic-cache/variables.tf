variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnets_ids" {
  type = list(string)
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
}