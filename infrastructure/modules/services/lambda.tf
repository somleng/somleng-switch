resource "aws_lambda_function" "this" {
  function_name = var.identifier
  role          = aws_iam_role.this.arn
  package_type  = "Image"
  architectures = ["arm64"]
  image_uri     = docker_registry_image.this.name
  timeout       = 300
  memory_size   = 512

  vpc_config {
    security_group_ids = [aws_security_group.this.id, var.db_security_group.id]
    subnet_ids         = var.vpc.private_subnets
  }

  environment {
    variables = {
      SWITCH_GROUP                                = "service:${var.switch_group}"
      MEDIA_PROXY_GROUP                           = "service:${var.media_proxy_group}"
      CLIENT_GATEWAY_GROUP                        = "service:${var.client_gateway_group}"
      FS_EVENT_SOCKET_PASSWORD_SSM_PARAMETER_NAME = var.freeswitch_event_socket_password_parameter.name
      FS_EVENT_SOCKET_PORT                        = var.freeswitch_event_socket_port
      FS_SIP_PORT                                 = var.sip_port
      FS_SIP_ALTERNATIVE_PORT                     = var.sip_alternative_port
      PUBLIC_GATEWAY_DB_NAME                      = var.public_gateway_db_name
      CLIENT_GATEWAY_DB_NAME                      = var.client_gateway_db_name
      MEDIA_PROXY_NG_PORT                         = var.media_proxy_ng_port
      DB_PASSWORD_SSM_PARAMETER_NAME              = var.db_password_parameter.name
      APP_MASTER_KEY_SSM_PARAMETER_NAME           = aws_ssm_parameter.application_master_key.name
      REGION_DATA_SSM_PARAMETER_NAME              = data.aws_ssm_parameter.region_data.name
      APP_ENV                                     = var.app_environment
      DB_HOST                                     = var.db_host
      DB_PORT                                     = var.db_port
      DB_USER                                     = var.db_username
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this
  ]

  lifecycle {
    ignore_changes = [
      image_uri
    ]
  }
}

resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

resource "aws_cloudwatch_event_rule" "this" {
  name = var.identifier

  event_pattern = jsonencode({
    source      = ["aws.ecs"],
    detail-type = ["ECS Task State Change"],
    detail = {
      clusterArn = [var.ecs_cluster.arn]
    }
  })
}

resource "aws_cloudwatch_event_target" "this" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.id
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn                   = aws_sqs_queue.this.arn
  function_name                      = aws_lambda_function.this.arn
  maximum_batching_window_in_seconds = 0
}
