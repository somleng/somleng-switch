resource "aws_iam_role" "this" {
  name = var.identifier
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_access_execution_role" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "custom_policy" {
  name = var.identifier

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
        ]
        Effect = "Allow"
        Resource = [
          var.freeswitch_event_socket_password_parameter.arn,
          aws_ssm_parameter.application_master_key.arn,
          var.db_password_parameter.arn,
          var.call_platform_password_parameter.arn,
          data.aws_ssm_parameter.region_data.arn,
        ]
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect = "Allow"
        Resource = [
          aws_sqs_queue.this.arn
        ]
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ecs:DescribeContainerInstances",
          "ecs:ListTasks"
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.custom_policy.arn
}
