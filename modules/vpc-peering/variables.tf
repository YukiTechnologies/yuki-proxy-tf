variable "yuki_vpc_id" {
  description = "Yuki VPC Id"
}

variable "yuki_vpc_cidr" {
  description = "Yuki CIDR block"
}

variable "yuki_vpc_private_route_table_ids" {
  description = "Yuki Route table id"
  type = list(string)
}

variable "yuki_vpc_public_route_table_ids" {
  description = "Yuki Route table id"
  type = list(string)
}

variable "yuki_vpc_main_route_table_ids" {
  description = "Yuki Route table id"
  type = string
}

variable "yuki_vpc_default_security_group_id" {
  type = string
}

variable "yuki_vpc_azs" {
  type = list(string)
}

variable "client_vpc_config" {
  type = object({
    id = string
    cidr_blocks = list(string)
    route_53_zone_name = string
    route_table_ids = list(string)
  })
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
}