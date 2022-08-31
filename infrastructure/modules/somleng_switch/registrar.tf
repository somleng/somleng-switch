# Container Instances
module registrar_container_instances {
  source = "../container_instances"

  app_identifier = "${var.app_identifier}-registrar"
  vpc_id = var.vpc_id
  instance_subnets = var.public_subnets
  cluster_name = aws_ecs_cluster.cluster.name
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "registrar" {
  name = "${var.app_identifier}-registrar"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.registrar_container_instances.autoscaling_group.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

# Security Group

resource "aws_security_group_rule" "registrar_healthcheck" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "tcp"
  from_port         = var.sip_port
  security_group_id = module.registrar_container_instances.security_group.id
  cidr_blocks = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "registrar_sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "udp"
  from_port         = var.sip_port
  security_group_id = module.registrar_container_instances.security_group.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "registrar_icmp" {
  type              = "ingress"
  to_port           = -1
  protocol          = "icmp"
  from_port         = -1
  security_group_id = module.registrar_container_instances.security_group.id
  cidr_blocks = ["0.0.0.0/0"]
}

# IAM
resource "aws_iam_role" "registrar_task_role" {
  name = "${var.app_identifier}-ecs-registrarTaskRole"

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

resource "aws_iam_role" "registrar_task_execution_role" {
  name = "${var.app_identifier}-ecs-registrarTaskExecutionRole"

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

resource "aws_iam_policy" "registrar_task_execution_custom_policy" {
  name = "${var.app_identifier}-registrar-task-execution-custom-policy"

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

resource "aws_iam_role_policy_attachment" "registrar_task_execution_custom_policy" {
  role = aws_iam_role.registrar_task_execution_role.id
  policy_arn = aws_iam_policy.registrar_task_execution_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "registrar_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role = aws_iam_role.registrar_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Groups
resource "aws_cloudwatch_log_group" "registrar" {
  name = "${var.app_identifier}-registrar"
  retention_in_days = 7
}

# ECS
data "template_file" "registrar" {
  template = file("${path.module}/templates/registrar.json.tpl")

  vars = {
    registrar_image = var.registrar_image

    registrar_logs_group = aws_cloudwatch_log_group.registrar.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    sip_port = var.sip_port

    database_password_parameter_arn = var.db_password_parameter_arn
    database_name = var.db_name
    database_username = var.db_username
    database_host = var.db_host
    database_port = var.db_port
  }
}

resource "aws_ecs_task_definition" "registrar" {
  family                   = "${var.app_identifier}-registrar"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  task_role_arn = aws_iam_role.registrar_task_role.arn
  execution_role_arn = aws_iam_role.registrar_task_execution_role.arn
  container_definitions = data.template_file.registrar.rendered
  memory = module.registrar_container_instances.ec2_instance_type.memory_size - 256
}

resource "aws_ecs_service" "registrar" {
  name            = aws_ecs_task_definition.registrar.family
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.registrar.arn
  desired_count   = var.registrar_min_tasks

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.registrar.name
    weight = 1
  }

  depends_on = [
    aws_iam_role.registrar_task_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Autoscaling
resource "aws_appautoscaling_policy" "registrar_policy" {
  name               = "registrar-scale"
  service_namespace  = aws_appautoscaling_target.registrar_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.registrar_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.registrar_scale_target.scalable_dimension
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

resource "aws_appautoscaling_target" "registrar_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.registrar.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.registrar_min_tasks
  max_capacity       = var.registrar_max_tasks
}
