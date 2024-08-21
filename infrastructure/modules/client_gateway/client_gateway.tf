data "aws_ip_ranges" "route53_healthchecks" {
  services = ["route53_healthchecks"]
}


# Container Instances
module "client_gateway_container_instances" {
  source = "../container_instances"

  app_identifier              = var.identifier
  vpc                         = var.vpc
  instance_subnets            = var.vpc.public_subnets
  associate_public_ip_address = true
  max_capacity                = var.max_tasks * 2
  cluster_name                = var.ecs_cluster.name
  security_groups             = [var.db_security_group.id]
  user_data = var.assign_eips ? [
    {
      path = "/opt/assign_eip.sh",
      content = templatefile(
        "${path.module}/templates/assign_eip.sh",
        {
          eip_tag = var.identifier
        }
      ),
      permissions = "755"
    }
  ] : []
}

# EIP
resource "aws_eip" "client_gateway" {
  count  = var.assign_eips ? var.max_tasks : 0
  domain = "vpc"

  tags = {
    Name             = "${var.identifier} ${count.index + 1}"
    (var.identifier) = "true"
    Priority         = count.index + 1
  }
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "client_gateway" {
  name = var.identifier

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.client_gateway_container_instances.autoscaling_group.arn
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

resource "aws_security_group_rule" "client_gateway_healthcheck" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "tcp"
  from_port         = var.sip_port
  security_group_id = module.client_gateway_container_instances.security_group.id
  cidr_blocks       = data.aws_ip_ranges.route53_healthchecks.cidr_blocks
}

resource "aws_security_group_rule" "client_gateway_sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "udp"
  from_port         = var.sip_port
  security_group_id = module.client_gateway_container_instances.security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "client_gateway_icmp" {
  type              = "ingress"
  to_port           = -1
  protocol          = "icmp"
  from_port         = -1
  security_group_id = module.client_gateway_container_instances.security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# IAM

resource "aws_iam_policy" "client_gateway_container_instance_custom_policy" {
  name = "${var.identifier}-container-instance-custom_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AssociateAddress",
        "ec2:DescribeAddresses"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "client_gateway_container_instance_custom_policy" {
  role       = module.client_gateway_container_instances.iam_role.id
  policy_arn = aws_iam_policy.client_gateway_container_instance_custom_policy.arn
}

resource "aws_iam_role" "client_gateway_task_execution_role" {
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

resource "aws_iam_policy" "client_gateway_task_execution_custom_policy" {
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

resource "aws_iam_role_policy_attachment" "client_gateway_task_execution_custom_policy" {
  role       = aws_iam_role.client_gateway_task_execution_role.id
  policy_arn = aws_iam_policy.client_gateway_task_execution_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "client_gateway_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role       = aws_iam_role.client_gateway_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Groups
resource "aws_cloudwatch_log_group" "client_gateway" {
  name              = var.identifier
  retention_in_days = 7
}

# ECS

resource "aws_ecs_task_definition" "client_gateway" {
  family                   = var.identifier
  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.client_gateway_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "client_gateway",
      image = "${var.app_image}:latest",
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.client_gateway.name,
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

  memory = module.client_gateway_container_instances.ec2_instance_type.memory_size - 512

  volume {
    name = "opensips"
  }
}

resource "aws_ecs_service" "client_gateway" {
  name                               = aws_ecs_task_definition.client_gateway.family
  cluster                            = var.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.client_gateway.arn
  desired_count                      = var.min_tasks
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.client_gateway.name
    weight            = 1
  }

  placement_constraints {
    type = "distinctInstance"
  }

  depends_on = [
    aws_iam_role.client_gateway_task_execution_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Autoscaling
resource "aws_appautoscaling_policy" "client_gateway_policy" {
  name               = "client_gateway-scale"
  service_namespace  = aws_appautoscaling_target.client_gateway_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.client_gateway_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.client_gateway_scale_target.scalable_dimension
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

resource "aws_appautoscaling_target" "client_gateway_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.client_gateway.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
}

# Route 53

resource "aws_route53_health_check" "client_gateway" {
  for_each = { for index, eip in aws_eip.client_gateway : index => eip }

  reference_name   = "${var.subdomain}-${each.key + 1}"
  ip_address       = each.value.public_ip
  port             = var.sip_port
  type             = "TCP"
  request_interval = 30

  tags = {
    Name = "${var.subdomain}-${each.key + 1}"
  }
}

resource "aws_route53_record" "client_gateway" {
  for_each = aws_route53_health_check.client_gateway
  zone_id  = var.route53_zone.zone_id
  name     = var.subdomain
  type     = "A"
  ttl      = 300
  records  = [each.value.ip_address]

  multivalue_answer_routing_policy = true
  set_identifier                   = "${var.identifier}-${each.key + 1}"
  health_check_id                  = each.value.id
}

resource "aws_lambda_invocation" "create_domain" {
  for_each      = aws_route53_record.client_gateway
  function_name = var.services_function.function_name

  input = jsonencode({
    serviceAction = "CreateDomain",
    parameters = {
      domain = each.value.fqdn
    }
  })
}
