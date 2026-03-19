resource "aws_cloudwatch_log_group" "this" {
  name              = var.identifier
  retention_in_days = 7
}
