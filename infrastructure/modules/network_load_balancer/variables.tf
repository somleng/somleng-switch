variable "identifier" {}
variable "vpc" {}
variable "logs_bucket" {}
variable "security_group_name" {
  default = null
}
locals {
  security_group_name = coalesce(var.security_group_name, "${var.identifier}-nlb")
}
