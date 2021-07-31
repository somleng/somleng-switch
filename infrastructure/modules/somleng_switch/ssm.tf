resource "aws_ssm_parameter" "application_master_key" {
  name  = "somleng_adhearsion.${var.app_environment}.application_master_key"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "rayo_password" {
  name  = "${var.app_identifier}.${var.app_environment}.rayo_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
