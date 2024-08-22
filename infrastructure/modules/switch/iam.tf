data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.identifier}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.identifier}-ecsTaskExecutionRole"

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
  name = "${var.identifier}-task-execution-custom-policy"

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
        "${local.application_master_key_parameter.arn}",
        "${local.rayo_password_parameter.arn}",
        "${local.freeswitch_event_socket_password_parameter.arn}",
        "${var.json_cdr_password_parameter.arn}",
        "${local.recordings_bucket_access_key_id_parameter.arn}",
        "${local.recordings_bucket_secret_access_key_parameter.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "${var.identifier}-ecs-task-policy"

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
        "${var.services_function.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_custom_policy" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_custom_policy" {
  role       = aws_iam_role.task_execution_role.id
  policy_arn = aws_iam_policy.task_execution_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
