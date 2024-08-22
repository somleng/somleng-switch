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
  value = aws_iam_access_key.recordings.id
}

resource "aws_ssm_parameter" "recordings_bucket_secret_access_key" {
  name  = "somleng-switch.${var.app_environment}.recordings_bucket_secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.recordings.secret
}
