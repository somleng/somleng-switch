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
      metrics {
        label = "Get the total number of FreeSWITCH sessions"
        id    = "m1"

        metric_stat {
          metric {
            metric_name = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.name[0]
            namespace   = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.namespace[0]

            dimensions {
              name  = "ServiceName"
              value = aws_ecs_service.this.name
            }
          }

          stat = "Sum"
        }

        return_data = false
      }

      metrics {
        label = "Get the total number of RUNNING tasks"
        id    = "m2"

        metric_stat {
          metric {
            metric_name = "RunningTaskCount"
            namespace   = "ECS/ContainerInsights"
            dimensions {
              name  = "ClusterName"
              value = var.ecs_cluster.name
            }
            dimensions {
              name  = "ServiceName"
              value = aws_ecs_service.this.name
            }
          }

          stat = "Average"
        }

        return_data = false
      }

      metrics {
        label       = "Calculate the number of sessions per running task"
        id          = "e1"
        expression  = "m1 / m2"
        return_data = true
      }
    }

    target_value       = 100
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# https://github.com/hashicorp/terraform-provider-aws/issues/40780
# Note that we need to also manually set the value
# Enable metric filter on transformed logs = true
# using the AWS console

resource "aws_cloudwatch_log_metric_filter" "freeswitch_session_count" {
  name           = "${var.identifier}-SessionCount"
  pattern        = "{ $.Session-Count = * }"
  log_group_name = aws_cloudwatch_log_group.freeswitch_event_logger.name

  metric_transformation {
    name      = "${var.identifier}-SessionCount"
    namespace = "SomlengSWITCH"
    value     = "$.Session-Count"
    dimensions = {
      ServiceName = "$.log-group-stream[0]"
    }
    unit = "Count"
  }

  depends_on = [null_resource.freeswitch_session_count_log_transformer]
}

resource "null_resource" "freeswitch_session_count_log_transformer" {
  triggers = {
    replace = local.freeswitch_session_count_log_transformer_command
  }

  provisioner "local-exec" {
    when    = create
    command = local.freeswitch_session_count_log_transformer_command
  }
}

locals {
  freeswitch_session_count_log_transformer_command = "aws logs put-transformer --region ${var.region.aws_region} --cli-input-json '${jsonencode(
    {
      logGroupIdentifier = aws_cloudwatch_log_group.freeswitch_event_logger.name,
      transformerConfig = [
        {
          parseJSON = {}
        },
        {
          copyValue = {
            entries = [
              {
                source            = "@logGroupName",
                target            = "log-group-name",
                overwriteIfExists = false
              },
              {
                source            = "@logGroupStream",
                target            = "log-group-stream",
                overwriteIfExists = false
              }
            ]
          }
        },
        {
          splitString = {
            entries = [
              {
                source    = "log-group-stream",
                delimiter = "/"
              }
            ]
          }
        }
      ]
    }
  )}'"
}
