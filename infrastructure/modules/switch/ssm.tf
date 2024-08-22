locals {
  recordings_bucket_access_key_id_parameter     = var.recordings_bucket_access_key_id_parameter != null ? var.recordings_bucket_access_key_id_parameter : module.recordings_bucket[0].access_key_id_parameter
  recordings_bucket_secret_access_key_parameter = var.recordings_bucket_secret_access_key_parameter != null ? var.recordings_bucket_secret_access_key_parameter : module.recordings_bucket[0].secret_access_key_parameter
  application_master_key_parameter              = var.application_master_key_parameter != null ? var.application_master_key_parameter : aws_ssm_parameter.application_master_key[0]
  rayo_password_parameter                       = var.rayo_password_parameter != null ? var.rayo_password_parameter : aws_ssm_parameter.rayo_password[0]
  freeswitch_event_socket_password_parameter    = var.freeswitch_event_socket_password_parameter != null ? var.freeswitch_event_socket_password_parameter : aws_ssm_parameter.freeswitch_event_socket_password[0]
}

resource "aws_ssm_parameter" "application_master_key" {
  count = var.application_master_key_parameter != null ? 0 : 1
  name  = var.application_master_key_parameter_name
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "rayo_password" {
  count = var.rayo_password_parameter != null ? 0 : 1
  name  = var.rayo_password_parameter_name
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "freeswitch_event_socket_password" {
  count = var.freeswitch_event_socket_password_parameter != null ? 0 : 1
  name  = var.freeswitch_event_socket_password_parameter_name
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
