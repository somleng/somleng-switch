resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.identifier}"
  retention_in_days = 7
}
