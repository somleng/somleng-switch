# Container Instances
module "container_instances" {
  source = "../container_instances"

  app_identifier   = var.identifier
  vpc              = var.vpc
  instance_subnets = var.vpc.private_subnets
  max_capacity     = var.max_tasks * 2
  cluster_name     = var.ecs_cluster.name
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "public_gateway" {
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

# Security Group
resource "aws_security_group" "public_gateway" {
  name   = var.identifier
  vpc_id = var.vpc.vpc_id
}

resource "aws_security_group_rule" "public_gateway_healthcheck" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "tcp"
  from_port         = var.sip_port
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks       = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "public_gateway_sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "udp"
  from_port         = var.sip_port
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_gateway_sip_alternative" {
  type              = "ingress"
  to_port           = var.sip_alternative_port
  protocol          = "udp"
  from_port         = var.sip_alternative_port
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_gateway_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Global Accelerator

resource "aws_globalaccelerator_listener" "public_gateway" {
  accelerator_arn = var.global_accelerator.id
  protocol        = "UDP"

  port_range {
    from_port = var.sip_port
    to_port   = var.sip_port
  }

  port_range {
    from_port = var.sip_alternative_port
    to_port   = var.sip_alternative_port
  }
}

resource "aws_globalaccelerator_endpoint_group" "public_gateway" {
  count        = var.min_tasks > 0 ? 1 : 0
  listener_arn = aws_globalaccelerator_listener.public_gateway.id

  endpoint_configuration {
    endpoint_id                    = aws_lb.public_gateway_nlb[count.index].arn
    client_ip_preservation_enabled = true
  }
}

# IAM
resource "aws_iam_role" "public_gateway_task_role" {
  name = "${var.identifier}-ecsTaskRole"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "public_gateway_task_execution_role" {
  name = "${var.identifier}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "public_gateway_task_execution_custom_policy" {
  name = "${var.identifier}-task-execution-custom-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": [
        "${var.db_password_parameter.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "public_gateway_task_execution_custom_policy" {
  role       = aws_iam_role.public_gateway_task_execution_role.id
  policy_arn = aws_iam_policy.public_gateway_task_execution_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "public_gateway_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role       = aws_iam_role.public_gateway_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Groups
resource "aws_cloudwatch_log_group" "public_gateway" {
  name              = var.identifier
  retention_in_days = 7
}

# ECS

resource "aws_ecs_task_definition" "public_gateway" {
  family                   = var.identifier
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.public_gateway_task_role.arn
  execution_role_arn       = aws_iam_role.public_gateway_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "public_gateway",
      image = "${var.app_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.public_gateway.name,
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
  name            = aws_ecs_task_definition.public_gateway.family
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.public_gateway.arn
  desired_count   = var.min_tasks

  network_configuration {
    subnets = var.vpc.private_subnets
    security_groups = [
      aws_security_group.public_gateway.id,
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
    capacity_provider = aws_ecs_capacity_provider.public_gateway.name
    weight            = 1
  }

  depends_on = [
    aws_iam_role.public_gateway_task_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Load Balancer

resource "aws_security_group" "public_gateway_nlb" {
  name   = "${var.identifier}-nlb"
  vpc_id = var.vpc.vpc_id
}

resource "aws_security_group_rule" "public_gateway_nlb_sip_ingress" {
  type        = "ingress"
  from_port   = var.sip_port
  to_port     = var.sip_port
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.public_gateway_nlb.id
}

resource "aws_security_group_rule" "public_gateway_nlb_sip_alternative_ingress" {
  type        = "ingress"
  from_port   = var.sip_alternative_port
  to_port     = var.sip_alternative_port
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.public_gateway_nlb.id
}

resource "aws_security_group_rule" "public_gateway_nlb_udp_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.public_gateway_nlb.id
}

resource "aws_security_group_rule" "public_gateway_nlb_tcp_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.public_gateway_nlb.id
}

resource "aws_eip" "public_gateway_nlb" {
  count  = var.min_tasks > 0 ? length(var.vpc.public_subnets) : 0
  domain = "vpc"

  tags = {
    Name = "Public Gateway NLB IP"
  }
}

resource "aws_lb" "public_gateway_nlb" {
  count                            = var.min_tasks > 0 ? 1 : 0
  name                             = var.identifier
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true

  security_groups = [aws_security_group.public_gateway_nlb.id]

  access_logs {
    bucket  = var.logs_bucket.id
    prefix  = var.identifier
    enabled = true
  }

  dynamic "subnet_mapping" {
    for_each = var.vpc.public_subnets
    content {
      subnet_id     = subnet_mapping.value
      allocation_id = aws_eip.public_gateway_nlb.*.id[subnet_mapping.key]
    }
  }
}

# Target Groups

resource "aws_lb_target_group" "sip" {
  name        = "${var.identifier}-sip"
  port        = var.sip_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc.vpc_id

  connection_termination = true

  health_check {
    protocol          = "TCP"
    port              = var.sip_port
    healthy_threshold = 3
    interval          = 10
  }
}

resource "aws_lb_listener" "sip" {
  count             = var.min_tasks > 0 ? 1 : 0
  load_balancer_arn = aws_lb.public_gateway_nlb[count.index].arn
  port              = var.sip_port
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sip.arn
  }
}

resource "aws_lb_target_group" "sip_alternative" {
  name        = "${var.identifier}-sip-alt"
  port        = var.sip_alternative_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc.vpc_id

  connection_termination = true

  health_check {
    protocol          = "TCP"
    port              = var.sip_port
    healthy_threshold = 3
    interval          = 10
  }
}

resource "aws_lb_listener" "sip_alternative" {
  count             = var.min_tasks > 0 ? 1 : 0
  load_balancer_arn = aws_lb.public_gateway_nlb[count.index].arn
  port              = var.sip_alternative_port
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sip_alternative.arn
  }
}

# Autoscaling
resource "aws_appautoscaling_policy" "public_gateway_policy" {
  count              = var.min_tasks > 0 ? 1 : 0
  name               = var.identifier
  service_namespace  = aws_appautoscaling_target.public_gateway_scale_target[count.index].service_namespace
  resource_id        = aws_appautoscaling_target.public_gateway_scale_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.public_gateway_scale_target[count.index].scalable_dimension
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
  count              = var.min_tasks > 0 ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.public_gateway[count.index].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
}
