resource "aws_cloudwatch_event_rule" "ecs" {
  name = "${var.identifier}-ecs-task-state-change"

  event_pattern = jsonencode({
    source      = ["aws.ecs"],
    detail-type = ["ECS Task State Change"],
    detail = {
      group = ["service:${var.identifier}"]
    }
  })
}

resource "aws_cloudwatch_event_target" "services" {
  arn  = var.services_function.this.arn
  rule = aws_cloudwatch_event_rule.ecs.id
}

resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = var.services_function.this.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs.arn
}
