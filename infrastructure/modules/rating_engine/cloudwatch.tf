resource "aws_cloudwatch_log_group" "app" {
  name              = var.identifier
  retention_in_days = 7
}
