variable "identifier" {}
variable "app_environment" {}
variable "configuration" {}
variable "min_tasks" {
  default = 1
}
variable "max_tasks" {
  default = 2
}
variable "lb_rule_index" {}
variable "region" {}
variable "ecs_cluster" {}
variable "internal_route53_zone" {}
