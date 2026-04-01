variable "identifier" {}
variable "image" {}
variable "stordb_password_parameter" {}
variable "stordb_dbname" {}
variable "stordb_host" {}
variable "stordb_port" {}
variable "stordb_user" {}
variable "stordb_ssl_mode" {
  default = "allow"
}

variable "datadb_cache" {}
variable "datadb_tls" {
  default = true
}

variable "connection_mode" {
  default = "*internal"
}
variable "json_rpc_url" {
  default = "/jsonrpc"
}
variable "json_rpc_username" {
  default = "cgrates"
}
variable "http_port" {
  default = 2080
}

variable "log_level" {
  default = 3
}

variable "connect_timeout" {
  default = "1s"
}

variable "reply_timeout" {
  default = "2s"
}
