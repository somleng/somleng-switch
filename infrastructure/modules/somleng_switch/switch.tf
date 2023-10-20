locals {
  efs_volume_name = "cache"
}

# Container Instances
module switch_container_instances {
  source = "../container_instances"

  app_identifier = var.switch_identifier
  vpc = var.vpc
  instance_subnets = var.vpc.private_subnets
  cluster_name = aws_ecs_cluster.cluster.name
  max_capacity = var.switch_max_tasks * 2
}

resource "aws_ecs_capacity_provider" "switch" {
  name = var.switch_identifier

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
resource "aws_cloudwatch_log_group" "switch_app" {
  name = "${var.switch_identifier}-app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx" {
  name = "${var.switch_identifier}-nginx"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch" {
  name = "${var.switch_identifier}-freeswitch"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "freeswitch_event_logger" {
  name = "${var.switch_identifier}-freeswitch-event-logger"
  retention_in_days = 7
}

# Security Group
resource "aws_security_group" "switch" {
  name   = var.switch_identifier
  vpc_id = var.vpc.vpc_id

  tags = {
    "Name" = var.switch_identifier
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
  cidr_blocks = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "switch_ingress_sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "UDP"
  from_port         = var.sip_port
  security_group_id = aws_security_group.switch.id
  cidr_blocks = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "switch_ingress_sip_alternative" {
  type              = "ingress"
  to_port           = var.sip_alternative_port
  protocol          = "UDP"
  from_port         = var.sip_alternative_port
  security_group_id = aws_security_group.switch.id
  cidr_blocks = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "switch_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}

# SSM Parameters
resource "aws_ssm_parameter" "switch_application_master_key" {
  name  = "somleng-switch.${var.app_environment}.application_master_key"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "rayo_password" {
  name  = "somleng-switch.${var.app_environment}.rayo_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name  = "somleng-switch.${var.app_environment}.freeswitch_event_socket_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "recordings_bucket_access_key_id" {
  name  = "somleng-switch.${var.app_environment}.recordings_bucket_access_key_id"
  type  = "SecureString"
  value = aws_iam_access_key.recordings.id
}

resource "aws_ssm_parameter" "recordings_bucket_secret_access_key" {
  name  = "somleng-switch.${var.app_environment}.recordings_bucket_secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.recordings.secret
}

# S3
resource "aws_s3_bucket" "recordings" {
  bucket = var.recordings_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    id = "rule-1"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_user" "recordings" {
  name = "${var.switch_identifier}_recordings"
}

resource "aws_iam_access_key" "recordings" {
  user = aws_iam_user.recordings.name
}

resource "aws_iam_user_policy" "recordings" {
  name = aws_iam_user.recordings.name
  user = aws_iam_user.recordings.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.recordings.arn}/*"
    }
  ]
}
EOF
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
  name               = "${var.switch_identifier}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.switch_identifier}-ecsTaskExecutionRole"

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
  name = "${var.switch_identifier}-task-execution-custom-policy"

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
        "${aws_ssm_parameter.switch_application_master_key.arn}",
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
  name = "${var.switch_identifier}-ecs-task-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "polly:DescribeVoices",
        "polly:SynthesizeSpeech"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "${aws_lambda_function.services.arn}"
      ]
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

# EFS
resource "aws_efs_file_system" "cache" {
  creation_token = var.efs_cache_name
  encrypted = true

  tags = {
    Name = var.efs_cache_name
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

resource "aws_efs_backup_policy" "cache" {
  file_system_id = aws_efs_file_system.cache.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "cache" {
  for_each = toset(var.vpc.intra_subnets)

  file_system_id = aws_efs_file_system.cache.id
  subnet_id      = each.value
  security_groups = [aws_security_group.efs_cache.id]
}

resource "aws_security_group" "efs_cache" {
  name   = "${var.switch_identifier}-efs-cache"
  vpc_id = var.vpc.vpc_id

  tags = {
    Name = "${var.switch_identifier}-cache"
  }
}

resource "aws_security_group_rule" "efs_cache_ingress" {
  type              = "ingress"
  protocol          = "TCP"
  security_group_id = aws_security_group.efs_cache.id
  cidr_blocks = [var.vpc.vpc_cidr_block]
  from_port = 2049
  to_port = 2049
}

# ECS
data "template_file" "switch" {
  template = file("${path.module}/templates/switch.json.tpl")

  vars = {
    name = var.switch_identifier
    app_image      = var.switch_app_image
    nginx_image      = var.nginx_image
    freeswitch_image = var.freeswitch_image
    freeswitch_event_logger_image = var.freeswitch_event_logger_image

    region = var.aws_region
    application_master_key_parameter_arn = aws_ssm_parameter.switch_application_master_key.arn
    freeswitch_event_socket_password_parameter_arn = aws_ssm_parameter.freeswitch_event_socket_password.arn
    freeswitch_event_socket_port = var.freeswitch_event_socket_port

    sip_port = var.sip_port
    sip_alternative_port = var.sip_alternative_port

    nginx_logs_group = aws_cloudwatch_log_group.nginx.name
    freeswitch_logs_group = aws_cloudwatch_log_group.freeswitch.name
    freeswitch_event_logger_logs_group = aws_cloudwatch_log_group.freeswitch_event_logger.name
    app_logs_group = aws_cloudwatch_log_group.switch_app.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    rayo_password_parameter_arn = aws_ssm_parameter.rayo_password.arn
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

    services_function_arn = aws_lambda_function.services.arn
  }
}

resource "aws_ecs_task_definition" "switch" {
  family                   = var.switch_identifier
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  container_definitions = data.template_file.switch.rendered
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
  memory = module.switch_container_instances.ec2_instance_type.memory_size - 512

  volume {
    name = local.efs_volume_name

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.cache.id
      transit_encryption      = "ENABLED"
    }
  }
}

resource "aws_ecs_service" "switch" {
  name            = var.switch_identifier
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.switch.arn
  desired_count   = var.switch_min_tasks

  network_configuration {
    subnets = var.vpc.private_subnets
    security_groups = [
      aws_security_group.switch.id
    ]
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.switch.name
    weight = 1
  }

  placement_constraints {
    type       = "distinctInstance"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.switch_http.arn
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

# Load Balancer
resource "aws_lb_target_group" "switch_http" {
  name = var.switch_identifier
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc.vpc_id
  target_type = "ip"
  deregistration_delay = 60

  health_check {
    protocol = "HTTP"
    path = "/health_checks"
    healthy_threshold = 3
    interval = 10
  }
}

resource "aws_lb_listener_rule" "switch_http" {
  priority = var.app_environment == "production" ? 20 : 120

  listener_arn = var.listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.switch_http.id
  }

  condition {
    host_header {
      values = [aws_route53_record.switch.fqdn]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

# Autoscaling
resource "aws_appautoscaling_target" "switch_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.switch.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.switch_min_tasks
  max_capacity       = var.switch_max_tasks
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
      statistic   = "Average"
      unit        = aws_cloudwatch_log_metric_filter.freeswitch_session_count.metric_transformation.*.unit[0]
    }

    target_value = 100
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_cloudwatch_log_metric_filter" "freeswitch_session_count" {
  name           = "${var.switch_identifier}-SessionCount"
  pattern        = "{ $.Session-Count = * }"
  log_group_name = aws_cloudwatch_log_group.freeswitch_event_logger.name

  metric_transformation {
    name      = "${var.switch_identifier}-SessionCount"
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
