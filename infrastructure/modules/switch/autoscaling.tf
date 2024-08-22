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
      statistic   = "Average"
      unit        = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.unit[0]
    }

    target_value       = 100
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_cloudwatch_log_metric_filter" "freeswitch_session_count" {
  name           = "${var.identifier}-SessionCount"
  pattern        = "{ $.Session-Count = * }"
  log_group_name = aws_cloudwatch_log_group.freeswitch_event_logger.name

  metric_transformation {
    name      = "${var.identifier}-SessionCount"
    namespace = "SomlengSWITCH"
    value     = "$.Session-Count"
    unit      = "Count"
  }
}
