resource "aws_ssm_parameter" "http_password" {
  name  = var.http_password_parameter_name
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "stordb_password" {
  name  = var.stordb_password_parameter_name
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
