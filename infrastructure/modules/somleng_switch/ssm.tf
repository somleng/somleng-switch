# SSM Parameters

data "aws_ssm_parameter" "db_password" {
  name = element(
    split("/", var.db_password_parameter_arn),
    length(split("/", var.db_password_parameter_arn)) - 1
  )
}
