data "template_file" "appserver_container_definitions" {
  template = file("${path.module}/templates/appserver_container_definitions.json.tpl")

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
    memory = var.memory
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
  }
}

resource "aws_ecs_task_definition" "appserver" {
  family                   = "${var.app_identifier}-appserver"
  network_mode             = var.network_mode
  requires_compatibilities = [var.launch_type]
  container_definitions = data.template_file.appserver_container_definitions.rendered
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
  cpu = var.cpu
  memory = var.memory
}

resource "local_file" "appserver_task_definition" {
  filename = "${path.module}/../../../deploy/${var.app_environment}/appserver_task_definition.json"
  file_permission = "644"
  content = <<EOF
{
  "family": "${aws_ecs_task_definition.appserver.family}",
  "networkMode": "${aws_ecs_task_definition.appserver.network_mode}",
  "cpu": "${aws_ecs_task_definition.appserver.cpu}",
  "memory": "${aws_ecs_task_definition.appserver.memory}",
  "executionRoleArn": "${aws_ecs_task_definition.appserver.execution_role_arn}",
  "taskRoleArn": "${aws_ecs_task_definition.appserver.task_role_arn}",
  "requiresCompatibilities": ["${var.launch_type}"],
  "containerDefinitions": ${aws_ecs_task_definition.appserver.container_definitions}
}
EOF
}

resource "aws_ecs_service" "appserver" {
  name            = "${var.app_identifier}-appserver"
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.appserver.arn
  desired_count   = var.ecs_appserver_autoscale_min_instances
  launch_type = var.launch_type

  network_configuration {
    subnets = var.container_instance_subnets
    security_groups = [aws_security_group.appserver.id, aws_security_group.freeswitch.id, var.db_security_group, data.aws_security_group.inbound_sip_trunks.id]
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
    ignore_changes = [load_balancer, task_definition]
  }
}
