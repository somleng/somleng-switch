resource "aws_ecs_capacity_provider" "this" {
  name = var.identifier

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.container_instances.autoscaling_group.arn
    managed_termination_protection = "ENABLED"
    managed_draining               = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.identifier
  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "media_proxy",
      image = "${var.app_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = var.app_environment
        }
      },
      essential = true,
      healthCheck = {
        command  = ["CMD-SHELL", "nc -z -w 5 $(hostname -i) $HEALTHCHECK_PORT"],
        interval = 10,
        retries  = 10,
        timeout  = 5
      },
      environment = [
        {
          name  = "NG_PORT",
          value = tostring(var.ng_port)
        },
        {
          name  = "MEDIA_PORT_MIN",
          value = tostring(var.media_port_min)
        },
        {
          name  = "MEDIA_PORT_MAX",
          value = tostring(var.media_port_max)
        },
        {
          name  = "HEALTHCHECK_PORT",
          value = tostring(var.healthcheck_port)
        }
      ]
    }
  ])

  memory = module.container_instances.ec2_instance_type.memory_size - 512
}

resource "aws_ecs_service" "this" {
  name            = aws_ecs_task_definition.this.family
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.min_tasks

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
  }

  placement_constraints {
    type = "distinctInstance"
  }

  depends_on = [
    aws_iam_role.task_execution_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
