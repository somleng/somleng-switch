locals {
  services_function_name = var.services_identifier
}

# Docker image

resource "docker_registry_image" "services" {
  name = "${var.services_ecr_repository_url}:latest"

  build {
    context = abspath("${path.module}/../../../docker/services")
  }

  lifecycle {
    ignore_changes = [
      build[0].context
    ]
  }
}

# SSM Parameters
resource "aws_ssm_parameter" "services_application_master_key" {
  name  = "somleng-switch-services.${var.app_environment}.application_master_key"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

# IAM
resource "aws_iam_role" "services" {
  name = local.services_function_name
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

resource "aws_iam_role_policy_attachment" "services_vpc_access_execution_role" {
  role       = aws_iam_role.services.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "services_custom_policy" {
  name = local.services_function_name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ssm:GetParameters",
      "Resource": [
        "${aws_ssm_parameter.freeswitch_event_socket_password.arn}",
        "${aws_ssm_parameter.services_application_master_key.arn}",
        "${var.db_password_parameter_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "${aws_sqs_queue.services.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeContainerInstances",
        "ec2:DescribeInstances"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "services_custom_policy" {
  role       = aws_iam_role.services.name
  policy_arn = aws_iam_policy.services_custom_policy.arn
}

# Security Group

resource "aws_security_group" "services" {
  name   = local.services_function_name
  vpc_id = var.vpc.vpc_id

  tags = {
    "Name" = local.services_function_name
  }
}

resource "aws_security_group_rule" "services_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.services.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lambda_function" "services" {
  function_name = local.services_function_name
  role = aws_iam_role.services.arn
  package_type = "Image"
  architectures = ["arm64"]
  image_uri = docker_registry_image.services.name
  timeout = 300
  memory_size = 512

  vpc_config {
    security_group_ids = [aws_security_group.services.id, var.db_security_group]
    subnet_ids = var.vpc.private_subnets
  }

  environment {
    variables = {
      SWITCH_GROUP = "service:${var.switch_identifier}"
      MEDIA_PROXY_GROUP = "service:${aws_ecs_task_definition.media_proxy.family}"
      CLIENT_GATEWAY_GROUP = "service:${aws_ecs_task_definition.client_gateway.family}"
      FS_EVENT_SOCKET_PASSWORD_SSM_PARAMETER_NAME = aws_ssm_parameter.freeswitch_event_socket_password.name
      FS_EVENT_SOCKET_PORT = var.freeswitch_event_socket_port
      FS_SIP_PORT = var.sip_port
      FS_SIP_ALTERNATIVE_PORT = var.sip_alternative_port
      PUBLIC_GATEWAY_DB_NAME = var.public_gateway_db_name
      CLIENT_GATEWAY_DB_NAME = var.client_gateway_db_name
      MEDIA_PROXY_NG_PORT = var.media_proxy_ng_port
      DB_PASSWORD_SSM_PARAMETER_NAME = data.aws_ssm_parameter.db_password.name
      APP_MASTER_KEY_SSM_PARAMETER_NAME = aws_ssm_parameter.services_application_master_key.name
      APP_ENV = var.app_environment
      DB_HOST = var.db_host
      DB_PORT = var.db_port
      DB_USER = var.db_username
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.services
  ]

  lifecycle {
    ignore_changes = [
      image_uri
    ]
  }
}

resource "aws_cloudwatch_log_group" "services" {
  name              = "/aws/lambda/${local.services_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "services" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.services.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.services.arn
}

resource "aws_cloudwatch_event_rule" "services" {
  name        = local.services_function_name

  event_pattern = <<EOF
{
  "source": ["aws.ecs"],
  "detail-type": ["ECS Task State Change"],
  "detail": {
    "clusterArn": ["${aws_ecs_cluster.cluster.arn}"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "services" {
  arn  = aws_lambda_function.services.arn
  rule = aws_cloudwatch_event_rule.services.id
}

# SQS

resource "aws_sqs_queue" "services_dead_letter" {
  name = "${var.services_identifier}-dead-letter"
}

resource "aws_sqs_queue" "services" {
  name           = var.services_identifier
  redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.services_dead_letter.arn}\",\"maxReceiveCount\":10}"

  # https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-queueconfig
  visibility_timeout_seconds = aws_lambda_function.services.timeout * 10
}

resource "aws_lambda_event_source_mapping" "services_sqs" {
  event_source_arn = aws_sqs_queue.services.arn
  function_name    = aws_lambda_function.services.arn
  maximum_batching_window_in_seconds = 0
}
