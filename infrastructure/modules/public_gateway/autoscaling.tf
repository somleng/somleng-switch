resource "aws_appautoscaling_policy" "public_gateway_policy" {
  name               = var.identifier
  service_namespace  = aws_appautoscaling_target.public_gateway_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.public_gateway_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.public_gateway_scale_target.scalable_dimension
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

resource "aws_appautoscaling_target" "public_gateway_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.public_gateway.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
}
