# https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html#LambdaFunctionExample

resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = var.services_function.this.arn
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.this.arn}*"
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = var.identifier
  log_group_name  = aws_cloudwatch_log_group.this.name
  filter_pattern  = "logtype test"
  destination_arn = var.services_function.this.arn
}
