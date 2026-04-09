variable "identifier" {}
variable "ecs_cluster" {}
variable "app_environment" {}
variable "lb_rule_index" {}
variable "region" {}
variable "call_platform_password_parameter" {}
variable "rating_engine_configuration" {}
variable "call_platform_host" {}
variable "call_platform_username" {}
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
variable "nginx_image" {}
variable "freeswitch_image" {}
variable "freeswitch_stats_logger_image" {}
variable "freeswitch_event_processor_image" {}
variable "external_sip_outbound_ip" {}
variable "nat_gateway_ip" {}
variable "alternative_sip_outbound_ip" {}
variable "nat_instance_ip" {}
variable "json_cdr_url" {}
variable "route53_record" {
  default = null
}
variable "sip_port" {}
variable "internal_sip_port" {}
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

variable "freeswitch_log_level" {
  default = "info"
}

variable "freeswitch_sip_trace" {
  default = "no"
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

variable "call_status_heartbeat_interval_seconds" {
  default = 30
}

variable "freeswitch_event_processor_sentry_dsn_parameter_name" {
  default = null
}

variable "freeswitch_event_processor_sentry_dsn_parameter" {
  default = null
}
