resource "aws_ssm_parameter" "access_key_id" {
  name  = var.access_key_id_parameter_name
  type  = "SecureString"
  value = aws_iam_access_key.this.id
}

resource "aws_ssm_parameter" "secret_access_key" {
  name  = var.secret_access_key_parameter_name
  type  = "SecureString"
  value = aws_iam_access_key.this.secret
}
