locals {
  cluster_name = var.app_identifier
  efs_volume_name = "cache"
}

resource "aws_ecs_cluster" "cluster" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }
}

resource "aws_ecs_capacity_provider" "container_instance" {
  name = var.app_identifier

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.container_instance.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = [aws_ecs_capacity_provider.container_instance.name]
}

data "template_file" "container_definitions" {
  template = file("${path.module}/templates/container_definitions.json.tpl")

  vars = {
    name = var.app_identifier
    app_port = var.app_port
    app_image      = var.app_image
    nginx_image      = var.nginx_image
    freeswitch_image = var.freeswitch_image
    freeswitch_event_logger_image = var.freeswitch_event_logger_image

    webserver_container_name = var.webserver_container_name
    webserver_container_port = var.webserver_container_port
    region = var.aws_region
    application_master_key_parameter_arn = aws_ssm_parameter.application_master_key.arn
    freeswitch_event_socket_password_parameter_arn = aws_ssm_parameter.freeswitch_event_socket_password.arn
    freeswitch_event_socket_port = var.freeswitch_event_socket_port

    nginx_logs_group = aws_cloudwatch_log_group.nginx.name
    freeswitch_logs_group = aws_cloudwatch_log_group.freeswitch.name
    freeswitch_event_logger_logs_group = aws_cloudwatch_log_group.freeswitch_event_logger.name
    app_logs_group = aws_cloudwatch_log_group.app.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    database_password_parameter_arn = var.db_password_parameter_arn
    rayo_password_parameter_arn = aws_ssm_parameter.rayo_password.arn
    rayo_port = var.rayo_port
    json_cdr_url = var.json_cdr_url
    json_cdr_password_parameter_arn = var.json_cdr_password_parameter_arn
    database_name = var.db_name
    database_username = var.db_username
    database_host = var.db_host
    database_port = var.db_port
    external_sip_ip = var.external_sip_ip
    external_rtp_ip = var.external_rtp_ip
    external_nat_instance_sip_ip = var.external_nat_instance_sip_ip
    external_nat_instance_rtp_ip = var.external_nat_instance_rtp_ip
    sip_port = var.sip_port
    sip_alternative_port = var.sip_alternative_port

    source_volume = local.efs_volume_name
    cache_directory = "/cache"

    recordings_bucket_name = aws_s3_bucket.recordings.id
    recordings_bucket_access_key_id_parameter_arn = aws_ssm_parameter.recordings_bucket_access_key_id.arn
    recordings_bucket_secret_access_key_parameter_arn = aws_ssm_parameter.recordings_bucket_secret_access_key.arn
    recordings_bucket_region = aws_s3_bucket.recordings.region
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.app_identifier
  network_mode             = var.network_mode
  requires_compatibilities = ["EC2"]
  container_definitions = data.template_file.container_definitions.rendered
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
  memory = data.aws_ec2_instance_type.container_instance.memory_size - 256

  volume {
    name = local.efs_volume_name

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.cache.id
      transit_encryption      = "ENABLED"
    }
  }
}

resource "local_file" "task_definition" {
  filename = "${path.module}/../../../deploy/${var.app_environment}/ecs_task_definition.json"
  file_permission = "644"
  content = <<EOF
{
  "family": "${aws_ecs_task_definition.task_definition.family}",
  "networkMode": "${aws_ecs_task_definition.task_definition.network_mode}",
  "executionRoleArn": "${aws_ecs_task_definition.task_definition.execution_role_arn}",
  "taskRoleArn": "${aws_ecs_task_definition.task_definition.task_role_arn}",
  "requiresCompatibilities": ["EC2"],
  "containerDefinitions": ${aws_ecs_task_definition.task_definition.container_definitions},
  "memory": "${aws_ecs_task_definition.task_definition.memory}",
  "volumes": [
    {
      "name": "${aws_ecs_task_definition.task_definition.volume.*.name[0]}",
      "efsVolumeConfiguration": {
        "fileSystemId": "${aws_efs_file_system.cache.id}",
        "transitEncryption": "${aws_ecs_task_definition.task_definition.volume.*.efs_volume_configuration[0].*.transit_encryption[0]}"
      }
    }
  ]
}
EOF
}

resource "aws_ecs_service" "service" {
  name            = var.app_identifier
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.min_tasks

  network_configuration {
    subnets = var.container_instance_subnets
    security_groups = [
      aws_security_group.appserver.id,
      var.db_security_group,
      aws_security_group.inbound_sip_trunks.id
    ]
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.container_instance.name
    weight = 1
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.webserver_container_name
    container_port   = var.webserver_container_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sip.arn
    container_name   = "freeswitch"
    container_port   = var.sip_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sip_alternative.arn
    container_name   = "freeswitch"
    container_port   = var.sip_alternative_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    aws_iam_role.ecs_task_role
  ]
}
