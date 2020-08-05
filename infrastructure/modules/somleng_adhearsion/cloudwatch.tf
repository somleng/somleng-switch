resource "aws_cloudwatch_log_group" "app" {
  name = "${var.app_identifier}-app"
}

resource "aws_cloudwatch_log_group" "worker" {
  name ="${var.app_identifier}-worker"
}
