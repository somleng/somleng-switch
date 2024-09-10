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
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "public_gateway",
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
          protocol      = "udp"
        },
        {
          containerPort = var.sip_alternative_port,
          protocol      = "udp"
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "opensips",
          containerPath = "/var/opensips"
        }
      ],
      healthCheck = {
        command  = ["CMD-SHELL", "nc -z -w 5 $(hostname -i) $SIP_PORT"],
        interval = 10,
        retries  = 10,
        timeout  = 5
      },
      secrets = [
        {
          name      = "DATABASE_PASSWORD",
          valueFrom = var.db_password_parameter.arn
        }
      ],
      environment = [
        {
          name  = "FIFO_NAME",
          value = var.opensips_fifo_name
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
          value = tostring(var.db_port)
        },
        {
          name  = "SIP_PORT",
          value = tostring(var.sip_port)
        },
        {
          name  = "SIP_ALTERNATIVE_PORT",
          value = tostring(var.sip_alternative_port)
        },
        {
          name  = "SIP_ADVERTISED_IP",
          value = tostring(var.global_accelerator.ip_sets[0].ip_addresses[0])
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
          value = "lb_reload,address_reload"
        }
      ]
    }
  ])

  memory = max((module.container_instances.ec2_instance_type.memory_size - 512), 128)

  volume {
    name = "opensips"
  }
}

resource "aws_ecs_service" "public_gateway" {
  count           = var.min_tasks > 0 ? 1 : 0
  name            = aws_ecs_task_definition.this.family
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.min_tasks

  network_configuration {
    subnets = var.vpc.private_subnets
    security_groups = [
      aws_security_group.this.id,
      var.db_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sip.arn
    container_name   = "public_gateway"
    container_port   = var.sip_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sip_alternative.arn
    container_name   = "public_gateway"
    container_port   = var.sip_alternative_port
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [
    aws_iam_role.task_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
