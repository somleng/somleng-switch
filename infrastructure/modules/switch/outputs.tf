output "capacity_provider" {
  value = aws_ecs_capacity_provider.this
}

output "recordings_bucket" {
  value = local.recordings_bucket
}

output "recordings_bucket_access_key_id_parameter" {
  value = local.recordings_bucket_access_key_id_parameter
}

output "recordings_bucket_secret_access_key_parameter" {
  value = local.recordings_bucket_secret_access_key_parameter
}

output "application_master_key_parameter" {
  value = local.application_master_key_parameter
}

output "rayo_password_parameter" {
  value = local.rayo_password_parameter
}

output "freeswitch_event_socket_password_parameter" {
  value = local.freeswitch_event_socket_password_parameter
}

output "container_instances" {
  value = module.container_instances
}

output "iam_task_role" {
  value = local.iam_task_role
}

output "iam_task_execution_role" {
  value = local.iam_task_execution_role
}

output "identifier" {
  value = var.identifier
}

output "app_environment" {
  value = var.app_environment
}

output "json_cdr_url" {
  value = var.json_cdr_url
}

output "min_tasks" {
  value = var.min_tasks
}

output "max_tasks" {
  value = var.max_tasks
}

output "sip_port" {
  value = var.sip_port
}

output "cache_name" {
  value = var.cache_name
}

output "sip_alternative_port" {
  value = var.sip_alternative_port
}

output "freeswitch_event_socket_port" {
  value = var.freeswitch_event_socket_port
}

output "json_cdr_password_parameter" {
  value = var.json_cdr_password_parameter
}

output "services_function" {
  value = var.services_function
}

output "app_image" {
  value = var.app_image
}

output "nginx_image" {
  value = var.nginx_image
}

output "freeswitch_image" {
  value = var.freeswitch_image
}

output "freeswitch_event_logger_image" {
  value = var.freeswitch_event_logger_image
}

output "internal_route53_zone" {
  value = var.internal_route53_zone
}

output "target_group" {
  value = aws_lb_target_group.this
}

output "target_event_bus" {
  value = var.target_event_bus == null ? var.region.event_bus : var.target_event_bus
}

output "lb_rule_index" {
  value = var.lb_rule_index
}
