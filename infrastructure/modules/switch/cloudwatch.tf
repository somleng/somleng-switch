resource "aws_cloudwatch_log_group" "app" {
  name              = "${var.identifier}-app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "${var.identifier}-nginx"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch" {
  name              = "${var.identifier}-freeswitch"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch_event_logger" {
  name              = "${var.identifier}-freeswitch-event-logger"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "${var.identifier}-redis"
  retention_in_days = 7
}
