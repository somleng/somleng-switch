locals {
  ecs_event_runner_function_name = "${var.app_identifier}_ecs_event_runner"
}

data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  registry_auth {
    address  = split("/", var.ecs_event_runner_ecr_repository_url)[0]
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
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

resource "aws_lambda_function" "ecs_event_runner" {
  function_name = local.ecs_event_runner_function_name
  role = aws_iam_role.ecs_event_runner.arn
  package_type = "Image"
  architectures = ["arm64"]
  image_uri = docker_registry_image.ecs_event_runner.name
  timeout = 300
  memory_size = 1024

  depends_on = [
    aws_iam_role_policy_attachment.ecs_event_runner,
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

resource "aws_iam_policy" "ecs_event_runner" {
  name = local.ecs_event_runner_function_name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ecs:DescribeTasks",
      "Resource": "arn:aws:ecs:*:*:task/${aws_ecs_task_definition.task_definition.family}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_event_runner" {
  role       = aws_iam_role.ecs_event_runner.name
  policy_arn = aws_iam_policy.ecs_event_runner.arn
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
  }
}
EOF
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
