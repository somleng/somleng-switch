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
  name  = "somleng-switch.${var.app_environment}.recordings_bucket_access_key_id"
  type  = "SecureString"
  value = module.recordings_bucket.access_key_id
}

resource "aws_ssm_parameter" "recordings_bucket_secret_access_key" {
  name  = "somleng-switch.${var.app_environment}.recordings_bucket_secret_access_key"
  type  = "SecureString"
  value = module.recordings_bucket.secret_access_key
}

resource "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name  = "somleng-switch.${var.app_environment}.freeswitch_event_socket_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
