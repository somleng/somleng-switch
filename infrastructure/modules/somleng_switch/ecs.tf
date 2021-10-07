locals {
  cluster_name = var.app_identifier
}

resource "aws_ecs_cluster" "cluster" {
  name = local.cluster_name
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
    webserver_container_name = var.webserver_container_name
    webserver_container_port = var.webserver_container_port
    region = var.aws_region
    application_master_key_parameter_arn = aws_ssm_parameter.application_master_key.arn
    nginx_logs_group = aws_cloudwatch_log_group.nginx.name
    freeswitch_logs_group = aws_cloudwatch_log_group.freeswitch.name
    app_logs_group = aws_cloudwatch_log_group.app.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment

    database_password_parameter_arn = var.db_password_parameter_arn
    rayo_password_parameter_arn = aws_ssm_parameter.rayo_password.arn
    rayo_port = var.rayo_port
    json_cdr_url = var.json_cdr_url
    json_cdr_password_parameter_arn = var.json_cdr_password_parameter_arn
    database_name = "freeswitch"
    database_username = var.db_username
    database_host = var.db_host
    database_port = var.db_port
    external_sip_ip = var.external_sip_ip
    external_rtp_ip = var.external_rtp_ip
    sip_port = var.sip_port

    tts_cache_bucket = aws_s3_bucket.tts_cache.id
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.app_identifier
  network_mode             = var.network_mode
  requires_compatibilities = ["EC2"]
  container_definitions = data.template_file.container_definitions.rendered
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
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
  "containerDefinitions": ${aws_ecs_task_definition.task_definition.container_definitions}
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
    security_groups = [aws_security_group.appserver.id, var.db_security_group, data.aws_security_group.inbound_sip_trunks.id]
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

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_iam_role.ecs_task_role
  ]
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
