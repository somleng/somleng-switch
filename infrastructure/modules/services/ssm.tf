data "aws_ssm_parameter" "region_data" {
  name = "somleng.${var.app_environment}.region_data"
}

data "aws_ssm_parameter" "call_platform_password" {
  name = "somleng.${var.app_environment}.services_password"
}

resource "aws_ssm_parameter" "application_master_key" {
  name  = "somleng-switch-services.${var.app_environment}.application_master_key"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
