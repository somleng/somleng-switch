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

output "cache_file_system" {
  value = local.cache_file_system
}

output "route53_record" {
  value = local.route53_record
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

output "internal_load_balancer" {
  value = var.internal_load_balancer
}

output "internal_listener" {
  value = var.internal_listener
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
