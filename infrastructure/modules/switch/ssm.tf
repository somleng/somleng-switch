locals {
  recordings_bucket_access_key_id_parameter     = var.recordings_bucket_access_key_id_parameter != null ? var.recordings_bucket_access_key_id_parameter : aws_ssm_parameter.recordings_bucket_access_key_id[0]
  recordings_bucket_secret_access_key_parameter = var.recordings_bucket_secret_access_key_parameter != null ? var.recordings_bucket_secret_access_key_parameter : aws_ssm_parameter.recordings_bucket_secret_access_key[0]
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

resource "aws_ssm_parameter" "recordings_bucket_access_key_id" {
  count = var.recordings_bucket_access_key_id_parameter == null ? 1 : 0
  name  = "somleng-switch.${var.app_environment}.recordings_bucket_access_key_id"
  type  = "SecureString"
  value = module.recordings_bucket[0].access_key_id
}

resource "aws_ssm_parameter" "recordings_bucket_secret_access_key" {
  count = var.recordings_bucket_secret_access_key_parameter == null ? 1 : 0
  name  = "somleng-switch.${var.app_environment}.recordings_bucket_secret_access_key"
  type  = "SecureString"
  value = module.recordings_bucket[0].secret_access_key
}

resource "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name  = "somleng-switch.${var.app_environment}.freeswitch_event_socket_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
