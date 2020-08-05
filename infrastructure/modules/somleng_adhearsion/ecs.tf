locals {
  database_name = replace(var.app_identifier, "-", "_")
}

data "template_file" "app_container_definitions" {
  template = file("${path.module}/templates/app_container_definitions.json.tpl")

  vars = {
    name = var.app_identifier
    app_image      = var.app_image
    region = var.aws_region
    aws_sqs_default_queue_name = aws_sqs_queue.this.name
    memory = var.memory
    app_logs_group = aws_cloudwatch_log_group.app.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment
    application_master_key_parameter_arn = aws_ssm_parameter.application_master_key.arn
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_identifier}-app"
  network_mode             = var.network_mode
  requires_compatibilities = [var.launch_type]
  container_definitions = data.template_file.app_container_definitions.rendered
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
  cpu = var.cpu
  memory = var.memory
}

resource "local_file" "app_task_definition" {
  filename = "${path.module}/../../../deploy/${var.app_environment}/app_task_definition.json"
  file_permission = "644"
  content = <<EOF
{
  "family": "${aws_ecs_task_definition.app.family}",
  "networkMode": "${aws_ecs_task_definition.app.network_mode}",
  "cpu": "${aws_ecs_task_definition.app.cpu}",
  "memory": "${aws_ecs_task_definition.app.memory}",
  "executionRoleArn": "${aws_ecs_task_definition.app.execution_role_arn}",
  "taskRoleArn": "${aws_ecs_task_definition.app.task_role_arn}",
  "requiresCompatibilities": ["${var.launch_type}"],
  "containerDefinitions": ${aws_ecs_task_definition.app.container_definitions}
}
EOF
}

resource "aws_ecs_service" "app" {
  name            = "${var.app_identifier}-app"
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_app_autoscale_min_instances
  launch_type = var.launch_type
  network_configuration {
    subnets = var.container_instance_subnets
    security_groups = [aws_security_group.app.id]
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

data "template_file" "worker_container_definitions" {
  template = file("${path.module}/templates/worker_container_definitions.json.tpl")

  vars = {
    name = var.app_identifier
    app_image      = var.app_image
    region = var.aws_region
    aws_sqs_default_queue_name = aws_sqs_queue.this.name
    memory = var.memory
    worker_logs_group = aws_cloudwatch_log_group.worker.name
    logs_group_region = var.aws_region
    app_environment = var.app_environment
    application_master_key_parameter_arn = aws_ssm_parameter.application_master_key.arn
  }
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.app_identifier}-worker"
  network_mode             = var.network_mode
  requires_compatibilities = [var.launch_type]
  container_definitions = data.template_file.worker_container_definitions.rendered
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
  cpu = var.cpu
  memory = var.memory
}

resource "local_file" "worker_task_definition" {
  filename = "${path.module}/../../../deploy/${var.app_environment}/worker_task_definition.json"
  file_permission = "644"
  content = <<EOF
{
  "family": "${aws_ecs_task_definition.worker.family}",
  "networkMode": "${aws_ecs_task_definition.worker.network_mode}",
  "cpu": "${aws_ecs_task_definition.worker.cpu}",
  "memory": "${aws_ecs_task_definition.worker.memory}",
  "executionRoleArn": "${aws_ecs_task_definition.worker.execution_role_arn}",
  "taskRoleArn": "${aws_ecs_task_definition.worker.task_role_arn}",
  "requiresCompatibilities": ["${var.launch_type}"],
  "containerDefinitions": ${aws_ecs_task_definition.worker.container_definitions}
}
EOF
}

resource "aws_ecs_service" "worker" {
  name            = "${var.app_identifier}-worker"
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.ecs_worker_autoscale_min_instances
  launch_type = var.launch_type

  network_configuration {
    subnets = var.container_instance_subnets
    security_groups = [aws_security_group.worker.id]
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
