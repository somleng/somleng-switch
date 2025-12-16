resource "aws_ssm_parameter" "http_password" {
  name  = "${var.identifier}.http_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
