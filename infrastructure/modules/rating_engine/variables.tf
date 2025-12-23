variable "identifier" {}
variable "app_environment" {}
variable "app_image" {}

variable "http_port" {
  default = 2080
}
variable "json_rpc_url" {
  default = "/jsonrpc"
}

variable "stordb_dbname" {}
variable "stordb_host" {}
variable "stordb_port" {}
variable "stordb_user" {}
variable "stordb_password_parameter_arn" {}
variable "stordb_security_group" {}
variable "stordb_ssl_mode" {
  default = "allow"
}
variable "datadb_tls" {
  default = true
}
variable "min_tasks" {
  default = 0
}
variable "max_tasks" {
  default = 2
}

variable "lb_rule_index" {}

variable "region" {}
variable "ecs_cluster" {}
variable "internal_route53_zone" {}
