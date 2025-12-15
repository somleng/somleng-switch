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
  container_definitions = jsonencode([
    {
      name  = "app",
      image = "${var.app_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = "${var.identifier}/${var.app_environment}"
        }
      },
      startTimeout = 120,
      essential    = true,
      portMappings = [
        {
          containerPort = var.http_port,
          protocol      = "tcp"
        }
      ],
      secrets = [
        {
          name      = "HTTP_PASSWORD",
          valueFrom = local.application_master_key_parameter.arn
        },
        {
          name  = "STORDB_PASSWORD",
          value = local.stordb_password_parameter.arn
        },
      ],
      environment = [
        {
          name  = "HTTP_LISTEN_ADDRESS",
          value = "127.0.0.1:${HTTP_PORT}"
        },
        {
          name  = "STORDB_DBNAME",
          value = var.stordb_dbname
        },
        {
          name  = "STORDB_HOST",
          value = var.stordb_dbname
        },
        {
          name  = "STORDB_PORT",
          value = tostring(var.stordb_port)
        },
        {
          name  = "STORDB_USER",
          value = var.stordb_user
        },
        {
          name  = "DATADB_USER",
          value = var.datadb_user
        },
        {
          name  = "DATADB_HOST",
          value = var.datadb_host
        },
        {
          name  = "DATADB_PORT",
          value = var.datadb_port
        },
        {
          name  = "DATADB_DBNAME",
          value = var.datadb_dbname
        },
      ]
    }
  ])

  task_role_arn      = local.iam_task_role.arn
  execution_role_arn = local.iam_task_execution_role.arn
  memory             = module.container_instances.ec2_instance_type.memory_size - 512
}

resource "aws_ecs_service" "this" {
  name            = var.identifier
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.min_tasks

  network_configuration {
    subnets = var.region.vpc.private_subnets
    security_groups = [
      aws_security_group.this.id
    ]
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
  }

  placement_constraints {
    type = "distinctInstance"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "app"
    container_port   = var.http_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_iam_role.ecs_task_role
  ]
}
