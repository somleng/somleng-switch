variable "identifier" {}
variable "app_environment" {}
variable "aws_region" {}
variable "vpc" {}
variable "ecs_cluster" {}
variable "app_image" {}
variable "services_function" {}

variable "ng_port" {
  default = 2223
}

variable "healthcheck_port" {
  default = 2224
}

variable "media_port_min" {
  default = 30000
}

variable "media_port_max" {
  default = 40000
}

variable "max_tasks" {
  default = 4
}

variable "min_tasks" {
  default = 1
}

variable "assign_eips" {
  default = false
}
