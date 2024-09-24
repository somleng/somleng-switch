variable "identifier" {}
variable "app_environment" {}
variable "aws_region" {}
variable "vpc" {}
variable "ecs_cluster" {}
variable "app_image" {}
variable "scheduler_image" {}
variable "sip_port" {}
variable "sip_alternative_port" {}
variable "db_security_group" {}
variable "db_password_parameter" {}
variable "db_name" {}
variable "db_username" {}
variable "db_host" {}
variable "db_port" {}
variable "global_accelerator" {}
variable "logs_bucket" {}

variable "opensips_fifo_name" {
  default = "/var/opensips/opensips_fifo"
}

variable "max_tasks" {
  default = 4
}

variable "min_tasks" {
  default = 1
}
