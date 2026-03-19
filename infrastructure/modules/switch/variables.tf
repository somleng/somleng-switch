variable "identifier" {}
variable "ecs_cluster" {}
variable "app_environment" {}
variable "lb_rule_index" {}
variable "region" {}
variable "call_platform_password_parameter" {}

variable "target_group_name" {
  default = null
}

variable "recordings_bucket_name" {
  default = null
}

variable "recordings_bucket" {
  default = null
}

variable "recordings_bucket_access_key_id_parameter_name" {
  default = null
}

variable "recordings_bucket_access_key_id_parameter" {
  default = null
}

variable "recordings_bucket_secret_access_key_parameter_name" {
  default = null
}

variable "recordings_bucket_secret_access_key_parameter" {
  default = null
}

variable "application_master_key_parameter_name" {
  default = null
}

variable "application_master_key_parameter" {
  default = null
}

variable "rayo_password_parameter_name" {
  default = null
}

variable "rayo_password_parameter" {
  default = null
}

variable "http_password_parameter_name" {
  default = null
}

variable "http_password_parameter" {
  default = null
}

variable "freeswitch_event_socket_password_parameter_name" {
  default = null
}

variable "freeswitch_event_socket_password_parameter" {
  default = null
}

variable "container_instance_profile" {
  default = null
}

variable "iam_task_role" {
  default = null
}

variable "iam_task_execution_role" {
  default = null
}

variable "target_event_bus" {
  default = null
}

variable "services_function" {}
variable "cache_name" {
  default = null
}
variable "cache_security_group_name" {
  default = null
}
variable "internal_route53_zone" {}
variable "app_image" {}
variable "rating_engine_image" {}
variable "nginx_image" {}
variable "freeswitch_image" {}
variable "freeswitch_event_logger_image" {}
variable "external_sip_outbound_ip" {}
variable "nat_gateway_ip" {}
variable "alternative_sip_outbound_ip" {}
variable "nat_instance_ip" {}
variable "json_cdr_url" {}
variable "route53_record" {
  default = null
}
variable "sip_port" {}
variable "sip_alternative_port" {}

variable "appserver_port" {
  default = 3000
}
variable "rayo_port" {
  default = 5222
}
variable "redis_port" {
  default = 6379
}
variable "freeswitch_event_socket_port" {
  default = 8021
}

variable "max_tasks" {
  default = 4
}

variable "min_tasks" {
  default = 1
}

variable "webserver_port" {
  default = 80
}

variable "rating_engine_http_port" {
  default = 2080
}

variable "rating_engine_json_rpc_password_parameter_arn" {
}

variable "rating_engine_stordb_password_parameter_arn" {
}

variable "rating_engine_stordb_dbname" {
}

variable "rating_engine_stordb_host" {
}

variable "rating_engine_stordb_port" {
}

variable "rating_engine_stordb_user" {
}

variable "rating_engine_stordb_ssl_mode" {
  default = "allow"
}

variable "rating_engine_datadb_cache" {
}

variable "rating_engine_datadb_tls" {
  default = true
}

variable "rating_engine_connection_mode" {
  default = "*internal"
}

variable "rating_engine_json_rpc_url" {
  default = "/jsonrpc"
}

variable "rating_engine_json_rpc_username" {
  default = "cgrates"
}
