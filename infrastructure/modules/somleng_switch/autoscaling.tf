resource "aws_appautoscaling_target" "appserver_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
}

resource "aws_appautoscaling_policy" "appserver_policy" {
  name               = "appserver-scale"
  service_namespace  = aws_appautoscaling_target.appserver_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.appserver_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appserver_scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 30
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "session_count" {
  name               = "appserver-session-count-scale"
  service_namespace  = aws_appautoscaling_target.appserver_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.appserver_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appserver_scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.name[0]
      namespace   = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.namespace[0]
      statistic   = "Maximum"
      unit        = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.unit[0]
    }

    target_value = 100
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_cloudwatch_log_metric_filter" "freeswitch_session_count" {
  name           = "${var.app_identifier}-SessionCount"
  pattern        = "{ $.Session-Count = * }"
  log_group_name = aws_cloudwatch_log_group.freeswitch_event_logger.name

  metric_transformation {
    name      = "${var.app_identifier}-SessionCount"
    namespace = "SomlengSWITCH"
    value     = "$.Session-Count"
    unit = "Count"
  }
}
