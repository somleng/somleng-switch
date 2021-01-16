resource "aws_cloudwatch_metric_alarm" "appserver_cpu_utilization_high" {
  alarm_name          = "${var.app_identifier}-CPU-Utilization-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_high_threshold_per

  dimensions = {
    ClusterName = var.ecs_cluster.name
    ServiceName = aws_ecs_service.appserver.name
  }

  alarm_actions = [aws_appautoscaling_policy.appserver_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "appserver_cpu_utilization_low" {
  alarm_name          = "${var.app_identifier}-CPU-Utilization-Low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.ecs_as_cpu_low_threshold_per

  dimensions = {
    ClusterName = var.ecs_cluster.name
    ServiceName = aws_ecs_service.appserver.name
  }

  alarm_actions = [aws_appautoscaling_policy.appserver_down.arn]
}


resource "aws_appautoscaling_policy" "appserver_up" {
  name               = "appserver-scale-up"
  service_namespace  = aws_appautoscaling_target.appserver_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.appserver_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appserver_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "appserver_down" {
  name               = "appserver-scale-down"
  service_namespace  = aws_appautoscaling_target.appserver_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.appserver_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appserver_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_target" "appserver_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.appserver.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_appserver_autoscale_max_instances
  min_capacity       = var.ecs_appserver_autoscale_min_instances
}
