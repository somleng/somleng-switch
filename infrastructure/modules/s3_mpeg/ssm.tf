resource "aws_ssm_parameter" "application_master_key" {
  name  = "s3-mpeg.${var.app_environment}.application_master_key"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
