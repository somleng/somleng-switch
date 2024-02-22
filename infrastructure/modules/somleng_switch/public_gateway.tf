# Container Instances
module public_gateway_container_instances {
  source = "../container_instances"

  app_identifier = var.public_gateway_identifier
  vpc = var.vpc
  instance_subnets = var.vpc.private_subnets
  max_capacity = var.public_gateway_max_tasks * 2
  cluster_name = aws_ecs_cluster.cluster.name
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "public_gateway" {
  name = var.public_gateway_identifier

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.public_gateway_container_instances.autoscaling_group.arn
    managed_termination_protection = "ENABLED"
    managed_draining = "ENABLED"

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
  name   = var.public_gateway_identifier
  vpc_id = var.vpc.vpc_id
}

resource "aws_security_group_rule" "public_gateway_healthcheck" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "tcp"
  from_port         = var.sip_port
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "public_gateway_sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "udp"
  from_port         = var.sip_port
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_gateway_sip_alternative" {
  type              = "ingress"
  to_port           = var.sip_alternative_port
  protocol          = "udp"
  from_port         = var.sip_alternative_port
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_gateway_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.public_gateway.id
  cidr_blocks = ["0.0.0.0/0"]
}

# IAM
resource "aws_iam_role" "public_gateway_task_role" {
  name = "${var.public_gateway_identifier}-ecsTaskRole"

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
  name = "${var.public_gateway_identifier}-ecsTaskExecutionRole"

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
  name = "${var.public_gateway_identifier}-task-execution-custom-policy"

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
        "${var.db_password_parameter_arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "public_gateway_task_execution_custom_policy" {
  role = aws_iam_role.public_gateway_task_execution_role.id
  policy_arn = aws_iam_policy.public_gateway_task_execution_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "public_gateway_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role = aws_iam_role.public_gateway_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Groups
resource "aws_cloudwatch_log_group" "public_gateway" {
  name = var.public_gateway_identifier
  retention_in_days = 7
}

# ECS
data "template_file" "public_gateway" {
  template = file("${path.module}/templates/public_gateway.json.tpl")

  vars = {
    public_gateway_image = var.public_gateway_image
    opensips_scheduler_image = var.opensips_scheduler_image

    logs_group = aws_cloudwatch_log_group.public_gateway.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    sip_port = var.sip_port
    sip_alternative_port = var.sip_alternative_port
    sip_advertised_ip = var.external_sip_ip

    database_password_parameter_arn = var.db_password_parameter_arn
    database_name = var.public_gateway_db_name
    database_username = var.db_username
    database_host = var.db_host
    database_port = var.db_port
  }
}

resource "aws_ecs_task_definition" "public_gateway" {
  family                   = var.public_gateway_identifier
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn = aws_iam_role.public_gateway_task_role.arn
  execution_role_arn = aws_iam_role.public_gateway_task_execution_role.arn
  container_definitions = data.template_file.public_gateway.rendered
  memory = module.public_gateway_container_instances.ec2_instance_type.memory_size - 512

  volume {
    name = "opensips"
  }
}

resource "aws_ecs_service" "public_gateway" {
  name            = aws_ecs_task_definition.public_gateway.family
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.public_gateway.arn
  desired_count   = var.public_gateway_min_tasks

  network_configuration {
    subnets = var.vpc.private_subnets
    security_groups = [
      aws_security_group.public_gateway.id,
      var.db_security_group
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
    weight = 1
  }

  depends_on = [
    aws_iam_role.public_gateway_task_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Load Balancer
resource "aws_lb_target_group" "sip" {
  name        = "${var.public_gateway_identifier}-sip"
  port        = var.sip_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc.vpc_id

  connection_termination = true

  health_check {
    protocol = "TCP"
    port = var.sip_port
    healthy_threshold = 3
    interval = 10
  }
}

resource "aws_lb_listener" "sip" {
  load_balancer_arn = var.network_load_balancer.arn
  port              = var.sip_port
  protocol          = "UDP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.sip.arn
  }
}

resource "aws_lb_target_group" "sip_alternative" {
  name        = "${var.public_gateway_identifier}-sip-alt"
  port        = var.sip_alternative_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc.vpc_id

  connection_termination = true

  health_check {
    protocol = "TCP"
    port = var.sip_port
    healthy_threshold = 3
    interval = 10
  }
}

resource "aws_lb_listener" "sip_alternative" {
  load_balancer_arn = var.network_load_balancer.arn
  port              = var.sip_alternative_port
  protocol          = "UDP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.sip_alternative.arn
  }
}

# Autoscaling
resource "aws_appautoscaling_policy" "public_gateway_policy" {
  name               = var.public_gateway_identifier
  service_namespace  = aws_appautoscaling_target.public_gateway_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.public_gateway_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.public_gateway_scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 30
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "public_gateway_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.public_gateway.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.public_gateway_min_tasks
  max_capacity       = var.public_gateway_max_tasks
}
