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

variable "node_type" {}
variable "num_cache_clusters" {
  default = 2
}

variable "automatic_failover_enabled" {
  default = true
}

variable "transit_encryption_enabled" {
  default = true
}

variable "transit_encryption_mode" {
  default = "required"
}
