
variable "aws_region" {}
variable "vpc" {}
variable "cluster_name" {}
variable "switch_identifier" {}
variable "services_identifier" {}
variable "s3_mpeg_identifier" {}
variable "public_gateway_identifier" {}
variable "client_gateway_identifier" {}
variable "media_proxy_identifier" {}
variable "app_environment" {}
variable "switch_app_image" {}
variable "nginx_image" {}
variable "freeswitch_image" {}
variable "opensips_scheduler_image" {}
variable "public_gateway_image" {}
variable "client_gateway_image" {}
variable "media_proxy_image" {}
variable "freeswitch_event_logger_image" {}
variable s3_mpeg_ecr_repository_url {}
variable services_ecr_repository_url {}
variable "load_balancer" {}
variable "network_load_balancer" {}
variable "listener_arn" {}
variable "switch_subdomain" {}
variable "client_gateway_subdomain" {}
variable "route53_zone" {}
variable "recordings_bucket_name" {}
variable "efs_cache_name" {}
variable "container_insights_enabled" {
  default = false
}
variable "assign_client_gateway_eips" {
  default = true
}

variable "assign_media_proxy_eips" {
  default = true
}

variable "switch_max_tasks" {
  default = 4
}
variable "switch_min_tasks" {
  default = 1
}
variable "public_gateway_max_tasks" {
  default = 4
}
variable "public_gateway_min_tasks" {
  default = 1
}
variable "client_gateway_min_tasks" {
  default = 1
}
variable "client_gateway_max_tasks" {
  default = 2
}
variable "media_proxy_min_tasks" {
  default = 1
}
variable "media_proxy_max_tasks" {
  default = 2
}

variable "media_proxy_media_port_min" {
  default = 30000
}

variable "media_proxy_media_port_max" {
  default = 40000
}

variable "media_proxy_ng_port" {
  default = 2223
}

# If the average CPU utilization over a minute drops to this threshold,
# the number of containers will be reduced (but not below ecs_autoscale_min_instances).
variable "ecs_as_cpu_low_threshold_per" {
  default = "20"
}

# If the average CPU utilization over a minute rises to this threshold,
# the number of containers will be increased (but not above ecs_autoscale_max_instances).
variable "ecs_as_cpu_high_threshold_per" {
  default = "70"
}

variable "freeswitch_event_socket_port" {
  default = 8021
}

variable "sip_port" {
  default = 5060
}

variable "sip_alternative_port" {
  default = 5080
}

variable "public_gateway_db_name" {}
variable "client_gateway_db_name" {}
variable "db_host" {}
variable "db_port" {}
variable "db_security_group" {}
variable "db_username" {}
variable "db_password_parameter_arn" {}

variable "json_cdr_password_parameter_arn" {}
variable "external_sip_ip" {}
variable "external_rtp_ip" {}
variable "alternative_sip_outbound_ip" {}
variable "alternative_rtp_ip" {}
variable "json_cdr_url" {}
variable "call_platform_stub_responses" {
  default = false
}
