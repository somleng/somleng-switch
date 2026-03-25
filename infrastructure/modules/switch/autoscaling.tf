resource "aws_appautoscaling_target" "scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
}

resource "aws_appautoscaling_policy" "policy" {
  name               = "switch-scale"
  service_namespace  = aws_appautoscaling_target.scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 30
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Note: Unlike a queue, this metric does not depend on the number of tasks running.
# This is similar to a CPU target value. The CPU average is over all tasks running.
# We want the AVERAGE session count to be around 100

resource "aws_appautoscaling_policy" "freeswitch_session_count" {
  name               = "freeswitch-session-count-scale"
  service_namespace  = aws_appautoscaling_target.scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.name[0]
      namespace   = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.namespace[0]
      unit        = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.unit[0]
      statistic   = "Average"

      dimensions {
        name  = "ServiceName"
        value = aws_ecs_service.this.name
      }
    }

    target_value       = 100
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_cloudwatch_log_metric_filter" "freeswitch_session_count" {
  name                      = "${var.identifier}-SessionCount"
  pattern                   = "{ $.Session-Count = * }"
  log_group_name            = aws_cloudwatch_log_group.freeswitch_event_logger.name
  apply_on_transformed_logs = true

  metric_transformation {
    name      = "${var.identifier}-SessionCount"
    namespace = "SomlengSWITCH"
    value     = "$.Session-Count"
    dimensions = {
      ServiceName = "$.log-group-stream[0]"
    }
    unit = "Count"
  }

  depends_on = [aws_cloudwatch_log_transformer.freeswitch_session_count]
}

resource "aws_cloudwatch_log_transformer" "freeswitch_session_count" {
  log_group_arn = aws_cloudwatch_log_group.freeswitch_event_logger.arn
  transformer_config {
    parse_json {}
  }

  transformer_config {
    copy_value {
      entry {
        source              = "@logGroupName"
        target              = "log-group-name"
        overwrite_if_exists = false
      }
      entry {
        source              = "@logGroupStream"
        target              = "log-group-stream"
        overwrite_if_exists = false
      }
    }
  }

  transformer_config {
    split_string {
      entry {
        source    = "log-group-stream"
        delimiter = "/"
      }
    }
  }
}
