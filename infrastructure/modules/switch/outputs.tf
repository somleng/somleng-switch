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
