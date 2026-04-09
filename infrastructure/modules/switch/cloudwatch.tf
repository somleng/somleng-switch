resource "aws_cloudwatch_log_group" "this" {
  name              = var.identifier
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch_stats_logger" {
  name              = "${var.identifier}-freeswitch-stats-logger"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch_event_processor" {
  name              = "${var.identifier}-freeswitch-event-processor"
  retention_in_days = 7
}
