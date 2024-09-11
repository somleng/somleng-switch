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
  count = var.services_function.aws_region == var.region.aws_region ? 1 : 0

  arn  = var.services_function.this.arn
  rule = aws_cloudwatch_event_rule.ecs.id
}

resource "aws_lambda_permission" "this" {
  count = var.services_function.aws_region == var.region.aws_region ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = var.services_function.this.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs.arn
}

resource "aws_cloudwatch_event_target" "event_bus" {
  count = var.services_function.aws_region != var.region.aws_region ? 1 : 0

  arn      = var.target_event_bus.this.arn
  role_arn = var.target_event_bus.target_role.arn
  rule     = aws_cloudwatch_event_rule.ecs.id
}
