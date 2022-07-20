
variable "aws_region" {}
variable "app_identifier" {}
variable "app_environment" {}
variable "app_image" {}
variable "nginx_image" {}
variable "freeswitch_image" {}
variable "opensips_image" {}
variable "freeswitch_event_logger_image" {}
variable s3_mpeg_ecr_repository_url {}
variable "container_instance_subnets" {}
variable "intra_subnets" {}
variable "vpc_id" {}
variable "load_balancer" {}
variable "network_load_balancer" {}
variable "listener_arn" {}
variable "sip_subdomain" {}
variable "switch_subdomain" {}
variable "route53_zone" {}
variable "listener_rule_priority" {}
variable "recordings_bucket_name" {}
variable "container_insights_enabled" {
  default = false
}

variable "webserver_container_name" {
  default = "nginx"
}

variable "webserver_container_port" {
  default = 80
}

variable "app_port" {
  default = 3000
}
variable "network_mode" {
  default = "awsvpc"
}
variable "enable_dashboard" {
  default = false
}
variable "max_tasks" {
  default = 4
}
variable "min_tasks" {
  default = 1
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

variable "rayo_port" {
  default = 5222
}

variable "freeswitch_event_socket_port" {
  default = 8021
}

variable "load_balancer_sip_port" {
  default = 5060
}

variable "load_balancer_sip_alternative_port" {
  default = 5080
}

variable "db_name" {}
variable "db_host" {}
variable "db_port" {}
variable "db_security_group" {}
variable "db_username" {}
variable "db_password_parameter_arn" {}

variable "json_cdr_password_parameter_arn" {}
variable "external_sip_ip" {}
variable "external_rtp_ip" {}
variable "alternative_sip_inbound_ip" {}
variable "alternative_sip_outbound_ip" {}
variable "alternative_rtp_ip" {}
variable "json_cdr_url" {}
variable "inbound_sip_trunks_security_group_name" {}
variable "inbound_sip_trunks_security_group_description" {
  default = "Somleng Inbound SIP Trunks"
}
