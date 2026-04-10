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
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = var.identifier
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
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = var.identifier
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
        },
        {
          name  = "FS_PORT",
          value = tostring(var.internal_sip_port)
        },
        {
          name  = "CALL_PLATFORM_HOST",
          value = var.call_platform_host
        },
        {
          name  = "CALL_PLATFORM_USERNAME",
          value = var.call_platform_username
        }
      ]
    },
    {
      name  = "freeswitch",
      image = "${var.freeswitch_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = var.identifier
        }
      },
      startTimeout = 120,
      healthCheck = {
        command = [
          "CMD-SHELL",
          "/usr/local/bin/healthcheck"
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
        },
        {
          name      = "FS_CALL_PLATFORM_PASSWORD",
          valueFrom = var.call_platform_password_parameter.arn
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
          name  = "FS_EXT_PROFILE_NAT_GATEWAY_SIP_PORT",
          value = tostring(var.sip_port)
        },
        {
          name  = "FS_EXT_PROFILE_NAT_GATEWAY_IP",
          value = var.nat_gateway_ip
        },
        {
          name  = "FS_EXT_PROFILE_UAS_NAT_INSTANCE_SIP_PORT",
          value = tostring(var.sip_alternative_port)
        },
        {
          name  = "FS_EXT_PROFILE_UAC_NAT_INSTANCE_SIP_PORT",
          value = tostring(var.sip_alternative_port + 1)
        },
        {
          name  = "FS_EXT_PROFILE_NAT_INSTANCE_IP",
          value = var.nat_instance_ip
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
          name  = "FS_LOG_LEVEL",
          value = var.freeswitch_log_level
        },
        {
          name  = "FS_SIP_TRACE",
          value = var.freeswitch_sip_trace
        },
        {
          name  = "FS_INTERNAL_SIP_PORT",
          value = tostring(var.internal_sip_port)
        },
        {
          name  = "FS_CALL_PLATFORM_HOST",
          value = var.call_platform_host
        },
        {
          name  = "FS_CALL_PLATFORM_USERNAME",
          value = var.call_platform_username
        },
        {
          name  = "FS_REGION",
          value = var.region.alias
        }
      ]
    },
    {
      name  = "redis",
      image = "public.ecr.aws/docker/library/redis:alpine",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = var.identifier
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
      name  = "freeswitch-stats-logger",
      image = "${var.freeswitch_stats_logger_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.freeswitch_stats_logger.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = var.identifier
        }
      },
      startTimeout = 120,
      essential    = true,
      secrets = [
        {
          name      = "EVENT_SOCKET_PASSWORD",
          valueFrom = local.freeswitch_event_socket_password_parameter.arn
        },
      ],
      dependsOn = [
        {
          containerName = "freeswitch",
          condition     = "HEALTHY"
        },
      ],
      environment = [
        {
          name  = "EVENT_SOCKET_HOST",
          value = "localhost:${var.freeswitch_event_socket_port}"
        },
      ]
    },
    {
      name  = "freeswitch-event-processor",
      image = "${var.freeswitch_event_processor_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.freeswitch_event_processor.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = var.identifier
        }
      },
      startTimeout = 120,
      essential    = true,
      secrets = [
        {
          name      = "EVENT_SOCKET_PASSWORD",
          valueFrom = local.freeswitch_event_socket_password_parameter.arn
        },
        {
          name      = "CALL_PLATFORM_PASSWORD",
          valueFrom = var.call_platform_password_parameter.arn
        },
        {
          name      = "SENTRY_DSN",
          valueFrom = local.freeswitch_event_processor_sentry_dsn_parameter.arn
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
      healthCheck = {
        command  = ["CMD-SHELL", "wget --server-response --spider --quiet http://localhost:$HEALTHCHECK_PORT/health 2>&1 | grep '200 OK' > /dev/null"],
        interval = 10,
        retries  = 10,
        timeout  = 5
      },
      environment = [
        {
          name  = "APP_ENV",
          value = var.app_environment
        },
        {
          name  = "EVENT_SOCKET_HOST",
          value = "localhost:${var.freeswitch_event_socket_port}"
        },
        {
          name  = "REDIS_URL",
          value = "redis://localhost:${var.redis_port}/1"
        },
        {
          name  = "CALL_STATUS_HEARTBEAT_INTERVAL_SECONDS",
          value = tostring(var.call_status_heartbeat_interval_seconds)
        },
        {
          name  = "CALL_PLATFORM_HOST",
          value = var.call_platform_host
        },
        {
          name  = "CALL_PLATFORM_USERNAME",
          value = var.call_platform_username
        },
        {
          name  = "HEALTHCHECK_PORT",
          value = "8080"
        },
      ]
    },
    {
      name  = "rating-engine",
      image = "${var.rating_engine_configuration.image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = var.region.aws_region,
          awslogs-stream-prefix = var.identifier
        }
      },
      startTimeout = 120,
      essential    = true,

      secrets = [
        {
          name      = "EVENT_SOCKET_PASSWORD",
          valueFrom = local.freeswitch_event_socket_password_parameter.arn
        },
        {
          name      = "JSON_RPC_PASSWORD",
          valueFrom = var.rating_engine_configuration.http_password_parameter.arn
        },
        {
          name      = "STORDB_PASSWORD",
          valueFrom = var.rating_engine_configuration.stordb_password_parameter.arn
        }
      ],
      dependsOn = [
        {
          containerName = "freeswitch",
          condition     = "HEALTHY"
        }
      ],
      healthCheck = {
        command  = ["CMD-SHELL", "/usr/local/bin/docker-healthcheck.sh"],
        interval = 10,
        retries  = 10,
        timeout  = 5
      },
      environment = [
        {
          name  = "SERVER_MODE",
          value = "engine"
        },
        {
          name  = "LOG_LEVEL",
          value = tostring(var.rating_engine_configuration.log_level)
        },
        {
          name  = "CONNECT_TIMEOUT",
          value = var.rating_engine_configuration.connect_timeout
        },
        {
          name  = "REPLY_TIMEOUT",
          value = var.rating_engine_configuration.reply_timeout
        },
        {
          name  = "STORDB_DBNAME",
          value = var.rating_engine_configuration.stordb_dbname
        },
        {
          name  = "STORDB_HOST",
          value = var.rating_engine_configuration.stordb_host
        },
        {
          name  = "STORDB_PORT",
          value = tostring(var.rating_engine_configuration.stordb_port)
        },
        {
          name  = "STORDB_USER",
          value = var.rating_engine_configuration.stordb_user
        },
        {
          name  = "STORDB_SSL_MODE",
          value = var.rating_engine_configuration.stordb_ssl_mode
        },
        {
          name  = "DATADB_HOST",
          value = var.rating_engine_configuration.datadb_cache.this.primary_endpoint_address
        },
        {
          name  = "DATADB_PORT",
          value = tostring(var.rating_engine_configuration.datadb_cache.this.port)
        },
        {
          name  = "DATADB_TLS",
          value = tostring(var.rating_engine_configuration.datadb_tls)
        },
        {
          name  = "CONNECTION_MODE",
          value = var.rating_engine_configuration.connection_mode
        },
        {
          name  = "EVENT_SOCKET_HOST",
          value = "localhost:${var.freeswitch_event_socket_port}"
        },
        {
          name  = "HTTP_LISTEN_ADDRESS",
          value = "0.0.0.0:${var.rating_engine_configuration.http_port}"
        },
        {
          name  = "JSON_RPC_URL",
          value = var.rating_engine_configuration.json_rpc_url
        },
        {
          name  = "JSON_RPC_USERNAME",
          value = var.rating_engine_configuration.json_rpc_username
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
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_iam_role.ecs_task_role
  ]
}
