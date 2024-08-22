variable "identifier" {}
variable "aws_region" {}
variable "vpc" {}
variable "ecs_cluster" {}
variable "app_environment" {}
variable "recordings_bucket_name" {}

variable "recordings_bucket" {
  default = null
}

variable "recordings_bucket_access_key_id_parameter" {
  default = null
}

variable "recordings_bucket_secret_access_key_parameter" {
  default = null
}

variable "json_cdr_password_parameter" {}
variable "services_function" {}
variable "efs_cache_name" {}
variable "internal_route53_zone" {}
variable "internal_load_balancer" {}
variable "internal_listener" {}
variable "app_image" {}
variable "nginx_image" {}
variable "freeswitch_image" {}
variable "freeswitch_event_logger_image" {}
variable "external_rtp_ip" {}
variable "alternative_sip_outbound_ip" {}
variable "alternative_rtp_ip" {}
variable "json_cdr_url" {}
variable "subdomain" {}
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
