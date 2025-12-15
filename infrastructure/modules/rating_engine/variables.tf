variable "identifier" {}
variable "app_environment" {}
variable "app_image" {
  default = "somleng/rating-engine"
}
variable "http_password_parameter_name" {}
variable "stordb_password_parameter_name" {}

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

variable "datadb_user" {}
variable "datadb_host" {}
variable "datadb_port" {}
variable "datadb_dbname" {}

variable "min_tasks" {
  default = 0
}
