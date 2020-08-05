resource "aws_ssm_parameter" "application_master_key" {
  name  = "somleng_adhearsion.${var.app_environment}.application_master_key"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
