locals {
  ecs_event_runner_function_name = "${var.app_identifier}_ecs_event_runner"
}

resource "docker_registry_image" "ecs_event_runner" {
  name = "${var.ecs_event_runner_ecr_repository_url}:latest"

  build {
    context = abspath("${path.module}/../../../docker/ecs_event_runner")
  }

  lifecycle {
    ignore_changes = [
      build[0].context
    ]
  }
}

resource "aws_iam_role" "ecs_event_runner" {
  name = local.ecs_event_runner_function_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_event_runner_vpc_access_execution_role" {
  role       = aws_iam_role.ecs_event_runner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "ecs_event_runner" {
  name   = local.ecs_event_runner_function_name
  vpc_id = var.vpc_id

  tags = {
    "Name" = local.ecs_event_runner_function_name
  }
}

resource "aws_security_group_rule" "ecs_event_runner_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.ecs_event_runner.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lambda_function" "ecs_event_runner" {
  function_name = local.ecs_event_runner_function_name
  role = aws_iam_role.ecs_event_runner.arn
  package_type = "Image"
  architectures = ["arm64"]
  image_uri = docker_registry_image.ecs_event_runner.name
  timeout = 300
  memory_size = 1024

  vpc_config {
    security_group_ids = [aws_security_group.ecs_event_runner.id, var.db_security_group]
    subnet_ids = var.container_instance_subnets
  }

  environment {
    variables = {
      SWITCH_GROUP = "service:${aws_ecs_task_definition.task_definition.family}",
      FS_EVENT_SOCKET_PASSWORD = aws_ssm_parameter.freeswitch_event_socket_password.value,
      FS_EVENT_SOCKET_PORT = 8021,
      OPENSIPS_LOAD_BALANCER_RESOURCE_TYPE = "pstn"
      OPENSIPS_DB_NAME = var.db_name,
      DB_PASSWORD = data.aws_ssm_parameter.db_password.value
      DB_HOST = var.db_host
      DB_PORT = var.db_port
      DB_USER = var.db_username
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.ecs_event_runner
  ]

  lifecycle {
    ignore_changes = [
      image_uri
    ]
  }
}

resource "aws_cloudwatch_log_group" "ecs_event_runner" {
  name              = "/aws/lambda/${local.ecs_event_runner_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "ecs_event_runner" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_event_runner.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_event_runner.arn
}

resource "aws_cloudwatch_event_rule" "ecs_event_runner" {
  name        = local.ecs_event_runner_function_name

  event_pattern = <<EOF
{
  "source": ["aws.ecs"],
  "detail-type": ["ECS Task State Change"],
  "detail": {
    "clusterArn": ["${aws_ecs_cluster.cluster.arn}"],
    "group": ["service:${aws_ecs_task_definition.task_definition.family}"]
  }
}
EOF
}
