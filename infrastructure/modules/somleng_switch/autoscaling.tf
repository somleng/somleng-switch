resource "aws_appautoscaling_target" "appserver_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.appserver.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_appserver_autoscale_max_instances
  min_capacity       = var.ecs_appserver_autoscale_min_instances
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

    target_value = 75
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
