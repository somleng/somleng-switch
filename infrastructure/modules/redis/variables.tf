locals {
  security_group_name = var.security_group_name == "" ? "${var.identifier}-${var.engine}" : var.security_group_name
}

variable "identifier" {}
variable "security_group_name" {
  default = ""
}
variable "vpc" {}
variable "engine" {
  default = "valkey"
}
