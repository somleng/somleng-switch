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
      healthCheck = {
        command  = ["CMD-SHELL", "/usr/local/bin/docker-healthcheck.sh"],
        interval = 10,
        retries  = 10,
        timeout  = 5
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
          name      = "JSON_RPC_PASSWORD",
          valueFrom = aws_ssm_parameter.http_password.arn
        },
        {
          name      = "STORDB_PASSWORD",
          valueFrom = var.stordb_password_parameter_arn
        },
      ],
      environment = [
        {
          name  = "SERVER_MODE",
          value = "api"
        },
        {
          name  = "HTTP_LISTEN_ADDRESS",
          value = "0.0.0.0:${var.http_port}"
        },
        {
          name  = "JSON_RPC_URL",
          value = var.json_rpc_url
        },
        {
          name  = "JSON_RPC_USERNAME",
          value = var.json_rpc_username
        },
        {
          name  = "CONNECTION_MODE",
          value = var.connection_mode
        },
        {
          name  = "STORDB_DBNAME",
          value = var.stordb_dbname
        },
        {
          name  = "STORDB_HOST",
          value = var.stordb_host
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
          name  = "STORDB_SSL_MODE",
          value = var.stordb_ssl_mode
        },
        {
          name  = "DATADB_HOST",
          value = var.datadb_cache.this.primary_endpoint_address
        },
        {
          name  = "DATADB_PORT",
          value = tostring(var.datadb_cache.this.port)
        },
        {
          name  = "DATADB_TLS",
          value = tostring(var.datadb_tls)
        }
      ]
    }
  ])

  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
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
      aws_security_group.this.id,
      var.stordb_security_group,
      var.datadb_cache.security_group.id
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
