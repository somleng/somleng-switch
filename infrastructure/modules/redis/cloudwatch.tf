resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.identifier}-valkey-cache"
  retention_in_days = 7
}
