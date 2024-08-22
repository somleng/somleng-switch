locals {
  recordings_bucket_access_key_id_parameter     = var.recordings_bucket_access_key_id_parameter != null ? var.recordings_bucket_access_key_id_parameter : module.recordings_bucket[0].access_key_id_parameter
  recordings_bucket_secret_access_key_parameter = var.recordings_bucket_secret_access_key_parameter != null ? var.recordings_bucket_secret_access_key_parameter : module.recordings_bucket[0].secret_access_key_parameter
}

resource "aws_ssm_parameter" "application_master_key" {
  name  = "somleng-switch.${var.app_environment}.application_master_key"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "rayo_password" {
  name  = "somleng-switch.${var.app_environment}.rayo_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name  = "somleng-switch.${var.app_environment}.freeswitch_event_socket_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
