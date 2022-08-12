module switch_container_instances {
  source = "../container_instances"

  app_identifier = var.app_identifier
  vpc_id = var.vpc_id
  instance_subnets = var.container_instance_subnets
  cluster_name = aws_ecs_cluster.cluster.name
}

resource "aws_ecs_capacity_provider" "switch" {
  name = var.app_identifier

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.switch_container_instances.autoscaling_group.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

# Log Groups
resource "aws_cloudwatch_log_group" "switch" {
  name = "${var.app_identifier}-switch"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx" {
  name = "${var.app_identifier}-nginx"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch" {
  name = "${var.app_identifier}-freeswitch"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch_event_logger" {
  name = "${var.app_identifier}-freeswitch-event-logger"
  retention_in_days = 7
}

# Security Group
resource "aws_security_group" "switch" {
  name   = "${var.app_identifier}-appserver"
  vpc_id = var.vpc_id

  tags = {
    "Name" = "${var.app_identifier}-switch"
  }
}

resource "aws_security_group_rule" "switch_ingress_http" {
  type              = "ingress"
  to_port           = 80
  protocol          = "TCP"
  from_port         = 80
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "switch_ingress_freeswitch_event_socket" {
  type              = "ingress"
  to_port           = 8021
  protocol          = "TCP"
  from_port         = 8021
  security_group_id = aws_security_group.switch.id
  cidr_blocks = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "switch_ingress_sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "UDP"
  from_port         = var.sip_port
  security_group_id = aws_security_group.switch.id
  cidr_blocks = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "switch_ingress_sip_alternative" {
  type              = "ingress"
  to_port           = var.sip_alternative_port
  protocol          = "UDP"
  from_port         = var.sip_alternative_port
  security_group_id = aws_security_group.switch.id
  cidr_blocks = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "switch_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}

# IAM

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app_identifier}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.app_identifier}-ecsTaskExecutionRole"

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

resource "aws_iam_policy" "task_execution_custom_policy" {
  name = "${var.app_identifier}-task-execution-custom-policy"

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
        "${aws_ssm_parameter.application_master_key.arn}",
        "${aws_ssm_parameter.rayo_password.arn}",
        "${aws_ssm_parameter.freeswitch_event_socket_password.arn}",
        "${var.json_cdr_password_parameter_arn}",
        "${aws_ssm_parameter.recordings_bucket_access_key_id.arn}",
        "${aws_ssm_parameter.recordings_bucket_secret_access_key.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "${var.app_identifier}-ecs-task-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "polly:SynthesizeSpeech"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_custom_policy" {
  role = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_custom_policy" {
  role = aws_iam_role.task_execution_role.id
  policy_arn = aws_iam_policy.task_execution_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role = aws_iam_role.task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "template_file" "switch" {
  template = file("${path.module}/templates/switch.json.tpl")

  vars = {
    name = var.app_identifier
    switch_image      = var.switch_image
    nginx_image      = var.nginx_image
    freeswitch_image = var.freeswitch_image
    freeswitch_event_logger_image = var.freeswitch_event_logger_image

    region = var.aws_region
    application_master_key_parameter_arn = aws_ssm_parameter.application_master_key.arn
    freeswitch_event_socket_password_parameter_arn = aws_ssm_parameter.freeswitch_event_socket_password.arn
    freeswitch_event_socket_port = var.freeswitch_event_socket_port

    sip_port = var.sip_port
    sip_alternative_port = var.sip_alternative_port

    nginx_logs_group = aws_cloudwatch_log_group.nginx.name
    freeswitch_logs_group = aws_cloudwatch_log_group.freeswitch.name
    freeswitch_event_logger_logs_group = aws_cloudwatch_log_group.freeswitch_event_logger.name
    switch_logs_group = aws_cloudwatch_log_group.switch.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    rayo_password_parameter_arn = aws_ssm_parameter.rayo_password.arn
    rayo_port = var.rayo_port
    json_cdr_url = var.json_cdr_url
    json_cdr_password_parameter_arn = var.json_cdr_password_parameter_arn
    external_rtp_ip = var.external_rtp_ip

    alternative_sip_outbound_ip = var.alternative_sip_outbound_ip
    alternative_rtp_ip = var.alternative_rtp_ip

    source_volume = local.efs_volume_name
    cache_directory = "/cache"

    recordings_bucket_name = aws_s3_bucket.recordings.id
    recordings_bucket_access_key_id_parameter_arn = aws_ssm_parameter.recordings_bucket_access_key_id.arn
    recordings_bucket_secret_access_key_parameter_arn = aws_ssm_parameter.recordings_bucket_secret_access_key.arn
    recordings_bucket_region = aws_s3_bucket.recordings.region
  }
}

resource "aws_ecs_task_definition" "switch" {
  family                   = var.app_identifier
  network_mode             = var.network_mode
  requires_compatibilities = ["EC2"]
  container_definitions = data.template_file.switch.rendered
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
  memory = module.switch_container_instances.ec2_instance_type.memory_size - 256

  volume {
    name = local.efs_volume_name

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.cache.id
      transit_encryption      = "ENABLED"
    }
  }
}

resource "local_file" "switch" {
  filename = "${path.module}/../../../deploy/${var.app_environment}/ecs_task_definition.json"
  file_permission = "644"
  content = <<EOF
{
  "family": "${aws_ecs_task_definition.switch.family}",
  "networkMode": "${aws_ecs_task_definition.switch.network_mode}",
  "executionRoleArn": "${aws_ecs_task_definition.switch.execution_role_arn}",
  "taskRoleArn": "${aws_ecs_task_definition.switch.task_role_arn}",
  "requiresCompatibilities": ["EC2"],
  "containerDefinitions": ${aws_ecs_task_definition.switch.container_definitions},
  "memory": "${aws_ecs_task_definition.switch.memory}",
  "volumes": [
    {
      "name": "${aws_ecs_task_definition.switch.volume.*.name[0]}",
      "efsVolumeConfiguration": {
        "fileSystemId": "${aws_efs_file_system.cache.id}",
        "transitEncryption": "${aws_ecs_task_definition.switch.volume.*.efs_volume_configuration[0].*.transit_encryption[0]}"
      }
    }
  ]
}
EOF
}

resource "aws_ecs_service" "switch" {
  name            = var.app_identifier
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.switch.arn
  desired_count   = var.min_tasks

  network_configuration {
    subnets = var.container_instance_subnets
    security_groups = [
      aws_security_group.switch.id
    ]
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.switch.name
    weight = 1
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "nginx"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    aws_iam_role.ecs_task_role
  ]
}

# Autoscaling

resource "aws_appautoscaling_target" "switch_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.switch.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_tasks
  max_capacity       = var.max_tasks
}

resource "aws_appautoscaling_policy" "switch_policy" {
  name               = "switch-scale"
  service_namespace  = aws_appautoscaling_target.switch_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.switch_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.switch_scale_target.scalable_dimension
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

resource "aws_appautoscaling_policy" "freeswitch_session_count" {
  name               = "freeswitch-session-count-scale"
  service_namespace  = aws_appautoscaling_target.switch_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.switch_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.switch_scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.name[0]
      namespace   = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.namespace[0]
      statistic   = "Maximum"
      unit        = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.unit[0]
    }

    target_value = 100
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_cloudwatch_log_metric_filter" "freeswitch_session_count" {
  name           = "${var.app_identifier}-SessionCount"
  pattern        = "{ $.Session-Count = * }"
  log_group_name = aws_cloudwatch_log_group.freeswitch_event_logger.name

  metric_transformation {
    name      = "${var.app_identifier}-SessionCount"
    namespace = "SomlengSWITCH"
    value     = "$.Session-Count"
    unit = "Count"
  }
}

# Route53
resource "aws_route53_record" "switch" {
  zone_id = var.route53_zone.zone_id
  name    = var.switch_subdomain
  type    = "A"

  alias {
    name                   = var.load_balancer.dns_name
    zone_id                = var.load_balancer.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sip" {
  zone_id = var.route53_zone.zone_id
  name    = var.sip_subdomain
  type    = "A"

  alias {
    name                   = var.network_load_balancer.dns_name
    zone_id                = var.network_load_balancer.zone_id
    evaluate_target_health = true
  }
}
