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
      name  = "nginx",
      image = "${var.nginx_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.nginx.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = "${var.identifier}/${var.app_environment}"
        }
      },
      essential = true,
      portMappings = [
        {
          containerPort = var.webserver_port,
          protocol      = "tcp"
        }
      ],
      dependsOn = [
        {
          containerName = "app",
          condition     = "HEALTHY"
        }
      ]
    },
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
          containerPort = var.appserver_port,
          protocol      = "tcp"
        }
      ],
      dependsOn = [
        {
          containerName = "redis",
          condition     = "HEALTHY"
        }
      ],
      healthCheck = {
        command  = ["CMD-SHELL", "wget --server-response --spider --quiet http://localhost:$AHN_CORE_HTTP_PORT/health_checks 2>&1 | grep '200 OK' > /dev/null"],
        interval = 10,
        retries  = 10,
        timeout  = 5
      },
      secrets = [
        {
          name      = "APP_MASTER_KEY",
          valueFrom = local.application_master_key_parameter.arn
        },
        {
          name      = "AHN_CORE_PASSWORD",
          valueFrom = local.rayo_password_parameter.arn
        },
        {
          name      = "AHN_HTTP_PASSWORD",
          valueFrom = local.http_password_parameter.arn
        },
        {
          name      = "CALL_PLATFORM_PASSWORD",
          valueFrom = var.call_platform_password_parameter.arn
        }
      ],
      environment = [
        {
          name  = "AHN_ENV",
          value = var.app_environment
        },
        {
          name  = "APP_ENV",
          value = var.app_environment
        },
        {
          name  = "RACK_ENV",
          value = var.app_environment
        },
        {
          name  = "AWS_DEFAULT_REGION",
          value = var.region.aws_region
        },
        {
          name  = "AHN_CORE_HTTP_PORT",
          value = tostring(var.appserver_port)
        },
        {
          name  = "AHN_CORE_PORT",
          value = tostring(var.rayo_port)
        },
        {
          name  = "SERVICES_FUNCTION_ARN",
          value = var.services_function.this.arn
        },
        {
          name  = "SERVICES_FUNCTION_REGION",
          value = var.services_function.aws_region
        },
        {
          name  = "REGION",
          value = var.region.alias
        },
        {
          name  = "REDIS_URL",
          value = "redis://localhost:${var.redis_port}/1"
        }
      ]
    },
    {
      name  = "freeswitch",
      image = "${var.freeswitch_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.freeswitch.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = "${var.identifier}/${var.app_environment}"
        }
      },
      startTimeout = 120,
      healthCheck = {
        command = [
          "CMD-SHELL",
          "fs_cli -p $FS_EVENT_SOCKET_PASSWORD -x 'rayo status' | rayo_status_parser"
        ]
        interval = 10,
        retries  = 10
        timeout  = 5
      }
      essential = true,
      portMappings = [
        {
          containerPort = var.rayo_port,
          protocol      = "tcp"
        },
        {
          containerPort = var.sip_port,
          protocol      = "udp"
        },
        {
          containerPort = var.sip_alternative_port,
          protocol      = "udp"
        },
        {
          containerPort = var.freeswitch_event_socket_port,
          protocol      = "tcp"
        }
      ],
      mountPoints = [
        {
          containerPath = "/cache",
          sourceVolume  = "cache"
        }
      ],
      secrets = [
        {
          name      = "FS_MOD_RAYO_PASSWORD",
          valueFrom = local.rayo_password_parameter.arn
        },
        {
          name      = "FS_MOD_JSON_CDR_PASSWORD",
          valueFrom = var.call_platform_password_parameter.arn
        },
        {
          name      = "FS_RECORDINGS_BUCKET_ACCESS_KEY_ID",
          valueFrom = local.recordings_bucket_access_key_id_parameter.arn
        },
        {
          name      = "FS_RECORDINGS_BUCKET_SECRET_ACCESS_KEY",
          valueFrom = local.recordings_bucket_secret_access_key_parameter.arn
        },
        {
          name      = "FS_EVENT_SOCKET_PASSWORD",
          valueFrom = local.freeswitch_event_socket_password_parameter.arn
        }
      ],
      environment = [
        {
          name  = "AWS_DEFAULT_REGION",
          value = var.region.aws_region
        },
        {
          name  = "FS_CACHE_DIRECTORY",
          value = "/cache"
        },
        {
          name  = "FS_STORAGE_DIRECTORY",
          value = "/cache/freeswitch/storage"
        },
        {
          name  = "FS_TTS_CACHE_DIRECTORY",
          value = "/cache/freeswitch/tts_cache"
        },
        {
          name  = "FS_LOG_DIRECTORY",
          value = "/cache/freeswitch/logs"
        },
        {
          name  = "FS_EXTERNAL_RTP_IP",
          value = var.external_rtp_ip
        },
        {
          name  = "FS_ALTERNATIVE_SIP_OUTBOUND_IP",
          value = var.alternative_sip_outbound_ip
        },
        {
          name  = "FS_ALTERNATIVE_RTP_IP",
          value = var.alternative_rtp_ip
        },
        {
          name  = "FS_MOD_RAYO_PORT",
          value = tostring(var.rayo_port)
        },
        {
          name  = "FS_MOD_JSON_CDR_URL",
          value = var.json_cdr_url
        },
        {
          name  = "FS_RECORDINGS_BUCKET_NAME",
          value = local.recordings_bucket.id
        },
        {
          name  = "FS_RECORDINGS_BUCKET_REGION",
          value = local.recordings_bucket.region
        },
        {
          name  = "FS_EVENT_SOCKET_PORT",
          value = tostring(var.freeswitch_event_socket_port)
        },
        {
          name  = "FS_SIP_PORT",
          value = tostring(var.sip_port)
        },
        {
          name  = "FS_SIP_ALTERNATIVE_PORT",
          value = tostring(var.sip_alternative_port)
        }
      ]
    },
    {
      name  = "redis",
      image = "public.ecr.aws/docker/library/redis:alpine",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = "${var.identifier}/${var.app_environment}"
        }
      },
      essential = true,
      healthCheck = {
        command  = ["CMD-SHELL", "redis-cli", "--raw", "incr", "ping"],
        interval = 10,
        retries  = 10,
        timeout  = 5
      },
      portMappings = [
        {
          containerPort = var.redis_port
        }
      ]
    },
    {
      name  = "freeswitch-event-logger",
      image = "${var.freeswitch_event_logger_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.freeswitch_event_logger.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = "${var.identifier}/${var.app_environment}"
        }
      },
      startTimeout = 120,
      essential    = true,
      secrets = [
        {
          name      = "EVENT_SOCKET_PASSWORD",
          valueFrom = local.freeswitch_event_socket_password_parameter.arn
        }
      ],
      dependsOn = [
        {
          containerName = "freeswitch",
          condition     = "HEALTHY"
        },
        {
          containerName = "redis",
          condition     = "HEALTHY"
        }
      ],
      environment = [
        {
          name  = "EVENT_SOCKET_HOST",
          value = "localhost:${var.freeswitch_event_socket_port}"
        },
        {
          name  = "REDIS_URL",
          value = "redis://localhost:${var.redis_port}/1"
        }
      ]
    }
  ])

  task_role_arn      = local.iam_task_role.arn
  execution_role_arn = local.iam_task_execution_role.arn
  memory             = module.container_instances.ec2_instance_type.memory_size - 512

  volume {
    name = "cache"

    efs_volume_configuration {
      file_system_id     = module.cache.file_system.id
      transit_encryption = "ENABLED"
    }
  }
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
    container_name   = "nginx"
    container_port   = var.webserver_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    aws_iam_role.ecs_task_role
  ]
}
