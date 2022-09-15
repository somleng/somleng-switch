# Container Instances
module media_proxy_container_instances {
  source = "../container_instances"

  app_identifier = var.media_proxy_identifier
  vpc = var.vpc
  instance_subnets = var.vpc.public_subnets
  cluster_name = aws_ecs_cluster.cluster.name
  user_data = [
    {
      path = "/opt/assign_eip.sh",
      content = templatefile(
        "${path.module}/templates/assign_eip.sh",
        {
          eip_tag = var.media_proxy_identifier
        }
      ),
      permissions = "755"
    }
  ]
}

resource "aws_eip" "media_proxy" {
  count = var.media_proxy_max_tasks
  vpc      = true

  tags = {
    Name = "Media Proxy ${count.index + 1}"
    (var.media_proxy_identifier) = "true"
    Priority = count.index + 1
  }
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "media_proxy" {
  name = var.media_proxy_identifier

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.media_proxy_container_instances.autoscaling_group.arn
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

resource "aws_security_group_rule" "media_proxy_control" {
  type              = "ingress"
  to_port           = var.media_proxy_ng_port
  protocol          = "udp"
  from_port         = var.media_proxy_ng_port
  security_group_id = module.media_proxy_container_instances.security_group.id
  cidr_blocks = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "media_proxy_media" {
  type              = "ingress"
  to_port           = var.media_proxy_media_port_max
  protocol          = "udp"
  from_port         = var.media_proxy_media_port_min
  security_group_id = module.media_proxy_container_instances.security_group.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "media_proxy_icmp" {
  type              = "ingress"
  to_port           = -1
  protocol          = "icmp"
  from_port         = -1
  security_group_id = module.media_proxy_container_instances.security_group.id
  cidr_blocks = ["0.0.0.0/0"]
}

# IAM

resource "aws_iam_policy" "media_proxy_container_instance_custom_policy" {
  name = "${var.media_proxy_identifier}-container-instance-custom_policy"

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

resource "aws_iam_role_policy_attachment" "media_proxy_container_instance_custom_policy" {
  role = module.media_proxy_container_instances.iam_role.id
  policy_arn = aws_iam_policy.media_proxy_container_instance_custom_policy.arn
}

resource "aws_iam_role" "media_proxy_task_execution_role" {
  name = "${var.media_proxy_identifier}-ecsTaskExecutionRole"

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

resource "aws_iam_role_policy_attachment" "media_proxy_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role = aws_iam_role.media_proxy_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Groups
resource "aws_cloudwatch_log_group" "media_proxy" {
  name = var.media_proxy_identifier
  retention_in_days = 7
}

# ECS
data "template_file" "media_proxy" {
  template = file("${path.module}/templates/media_proxy.json.tpl")

  vars = {
    media_proxy_image = var.media_proxy_image

    logs_group = aws_cloudwatch_log_group.media_proxy.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    ng_port = var.media_proxy_ng_port
    media_port_min = var.media_proxy_media_port_min
    media_port_max = var.media_proxy_media_port_max
  }
}

resource "aws_ecs_task_definition" "media_proxy" {
  family                   = var.media_proxy_identifier
  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  execution_role_arn = aws_iam_role.media_proxy_task_execution_role.arn
  container_definitions = data.template_file.media_proxy.rendered
  memory = module.media_proxy_container_instances.ec2_instance_type.memory_size - 256
}

resource "aws_ecs_service" "media_proxy" {
  name            = aws_ecs_task_definition.media_proxy.family
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.media_proxy.arn
  desired_count   = var.media_proxy_min_tasks
  deployment_minimum_healthy_percent = 50

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.media_proxy.name
    weight = 1
  }

  depends_on = [
    aws_iam_role.media_proxy_task_execution_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Autoscaling
resource "aws_appautoscaling_policy" "media_proxy_policy" {
  name               = "media_proxy-scale"
  service_namespace  = aws_appautoscaling_target.media_proxy_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.media_proxy_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.media_proxy_scale_target.scalable_dimension
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

resource "aws_appautoscaling_target" "media_proxy_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.media_proxy.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.media_proxy_min_tasks
  max_capacity       = var.media_proxy_max_tasks
}
