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
      name  = "client_gateway",
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
      portMappings = [
        {
          containerPort = var.sip_port,
          hostPort      = var.sip_port,
          protocol      = "udp"
        },
        {
          containerPort = var.sip_port,
          hostPort      = var.sip_port,
          protocol      = "tcp"
        }
      ],
      healthCheck = {
        command  = ["CMD-SHELL", "nc -z -w 5 $(hostname -i) $SIP_PORT"],
        interval = 10,
        retries  = 10,
        timeout  = 5
      },
      mountPoints = [
        {
          sourceVolume  = "opensips",
          containerPath = "/var/opensips"
        }
      ],
      secrets = [
        {
          name      = "DATABASE_PASSWORD",
          valueFrom = var.db_password_parameter.arn
        }
      ],
      environment = [
        {
          name  = "FIFO_NAME",
          value = var.opensips_fifo_name,
        },
        {
          name  = "DATABASE_NAME",
          value = var.db_name
        },
        {
          name  = "DATABASE_USERNAME",
          value = var.db_username
        },
        {
          name  = "DATABASE_HOST",
          value = var.db_host
        },
        {
          name  = "DATABASE_PORT",
          value = tostring(var.db_port),
        },
        {
          name  = "SIP_PORT",
          value = tostring(var.sip_port)
        }
      ]
    },
    {
      name      = "opensips_scheduler",
      image     = "${var.scheduler_image}:latest",
      essential = true,
      mountPoints = [
        {
          sourceVolume  = "opensips",
          containerPath = "/var/opensips"
        }
      ],
      environment = [
        {
          name  = "FIFO_NAME",
          value = var.opensips_fifo_name
        },
        {
          name  = "MI_COMMANDS",
          value = "lb_reload,domain_reload,rtpengine_reload"
        }
      ]
    }
  ])

  memory = module.container_instances.ec2_instance_type.memory_size - 512

  volume {
    name = "opensips"
  }
}

resource "aws_ecs_service" "this" {
  name                               = aws_ecs_task_definition.this.family
  cluster                            = var.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.min_tasks
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

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
