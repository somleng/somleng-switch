variable "instance_type" {
  default = "t3.small"
}

variable "app_identifier" {}
variable "vpc_id" {}
variable "instance_subnets" {}
variable "cluster_name" {}
variable "security_groups" {
  default = []
}
