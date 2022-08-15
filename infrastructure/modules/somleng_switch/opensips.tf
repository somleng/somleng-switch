# Container Instances
module opensips_container_instances {
  source = "../container_instances"

  app_identifier = "${var.app_identifier}-opensips"
  vpc_id = var.vpc_id
  instance_subnets = var.container_instance_subnets
  cluster_name = aws_ecs_cluster.cluster.name
}

resource "aws_security_group" "inbound_sip_trunks" {
  name   = var.inbound_sip_trunks_security_group_name
  description = var.inbound_sip_trunks_security_group_description
  vpc_id = var.vpc_id
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "opensips" {
  name = "${var.app_identifier}-opensips"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.opensips_container_instances.autoscaling_group.arn
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
resource "aws_security_group" "opensips" {
  name   = "${var.app_identifier}-opensips"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "opensips_healthcheck" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "tcp"
  from_port         = var.sip_port
  security_group_id = aws_security_group.opensips.id
  cidr_blocks = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "opensips_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.opensips.id
  cidr_blocks = ["0.0.0.0/0"]
}

# SSM Parameters
data "aws_ssm_parameter" "db_password" {
  name = element(
    split("/", var.db_password_parameter_arn),
    length(split("/", var.db_password_parameter_arn)) - 1
  )
}

# IAM
resource "aws_iam_role" "opensips_task_role" {
  name = "${var.app_identifier}-ecs-OpenSIPSTaskRole"

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

resource "aws_iam_role_policy_attachment" "opensips_task_role_cloudwatch_agent_server_policy" {
  role = aws_iam_role.ecs_cwagent_daemon_service_task_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role" "opensips_task_execution_role" {
  name = "${var.app_identifier}-ecs-OpenSIPSTaskExecutionRole"

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

resource "aws_iam_policy" "opensips_task_execution_custom_policy" {
  name = "${var.app_identifier}-opensips-task-execution-custom-policy"

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
        "${var.db_password_parameter_arn}",
        "${aws_ssm_parameter.freeswitch_event_socket_password.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "opensips_task_execution_custom_policy" {
  role = aws_iam_role.opensips_task_execution_role.id
  policy_arn = aws_iam_policy.opensips_task_execution_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "opensips_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role = aws_iam_role.opensips_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Groups
resource "aws_cloudwatch_log_group" "opensips" {
  name = "${var.app_identifier}-opensips"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "opensips_scheduler" {
  name = "${var.app_identifier}-opensips-scheduler"
  retention_in_days = 7
}

# ECS
data "template_file" "opensips" {
  template = file("${path.module}/templates/opensips.json.tpl")

  vars = {
    opensips_image = var.opensips_image
    opensips_scheduler_image = var.opensips_scheduler_image

    opensips_logs_group = aws_cloudwatch_log_group.opensips.name
    opensips_scheduler_logs_group = aws_cloudwatch_log_group.opensips_scheduler.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    sip_port = var.sip_port
    sip_alternative_port = var.sip_alternative_port
    sip_advertised_ip = var.external_sip_ip

    freeswitch_event_socket_password_parameter_arn = aws_ssm_parameter.freeswitch_event_socket_password.arn
    database_password_parameter_arn = var.db_password_parameter_arn
    database_name = var.db_name
    database_username = var.db_username
    database_host = var.db_host
    database_port = var.db_port
  }
}

resource "aws_ecs_task_definition" "opensips" {
  family                   = "${var.app_identifier}-opensips"
  network_mode             = var.network_mode
  requires_compatibilities = ["EC2"]
  task_role_arn = aws_iam_role.opensips_task_role.arn
  execution_role_arn = aws_iam_role.opensips_task_execution_role.arn
  container_definitions = data.template_file.opensips.rendered
  memory = module.opensips_container_instances.ec2_instance_type.memory_size - 256

  volume {
    name = "opensips"
  }
}

resource "local_file" "opensips_task_definition" {
  filename = "${path.module}/../../../docker/opensips/deploy/${var.app_environment}/ecs_task_definition.json"
  file_permission = "644"
  content = <<EOF
{
  "family": "${aws_ecs_task_definition.opensips.family}",
  "networkMode": "${aws_ecs_task_definition.opensips.network_mode}",
  "executionRoleArn": "${aws_ecs_task_definition.opensips.execution_role_arn}",
  "taskRoleArn": "${aws_ecs_task_definition.opensips.task_role_arn}",
  "requiresCompatibilities": ["EC2"],
  "containerDefinitions": ${aws_ecs_task_definition.opensips.container_definitions},
  "memory": "${aws_ecs_task_definition.opensips.memory}",
  "volumes": [
    {
      "name": "${aws_ecs_task_definition.opensips.volume.*.name[0]}"
    }
  ]
}
EOF
}

resource "aws_ecs_service" "opensips" {
  name            = aws_ecs_task_definition.opensips.family
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.opensips.arn
  desired_count   = var.min_tasks

  network_configuration {
    subnets = var.container_instance_subnets
    security_groups = [
      aws_security_group.opensips.id,
      var.db_security_group,
      aws_security_group.inbound_sip_trunks.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sip.arn
    container_name   = "opensips"
    container_port   = var.sip_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sip_alternative.arn
    container_name   = "opensips"
    container_port   = var.sip_alternative_port
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.opensips.name
    weight = 1
  }

  depends_on = [
    aws_iam_role.opensips_task_role
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Load Balancer
resource "aws_lb_target_group" "sip" {
  name        = "${var.app_identifier}-sip"
  port        = var.sip_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc_id

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
  name        = "${var.app_identifier}-sip-alt"
  port        = var.sip_alternative_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc_id

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
resource "aws_appautoscaling_policy" "opensips_policy" {
  name               = "opensips-scale"
  service_namespace  = aws_appautoscaling_target.opensips_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.opensips_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.opensips_scale_target.scalable_dimension
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

resource "aws_appautoscaling_target" "opensips_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.opensips.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.opensips_min_tasks
  max_capacity       = var.opensips_max_tasks
}
