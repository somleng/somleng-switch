# ECS task role
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app_identifier}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.app_identifier}-ecsTaskExecutionRole"

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
  name = "${var.app_identifier}-task-execution-custom-policy"

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
        "${aws_ssm_parameter.application_master_key.arn}",
        "${aws_ssm_parameter.rayo_password.arn}",
        "${var.json_cdr_password_parameter_arn}",
        "${var.db_password_parameter_arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "${var.app_identifier}-ecs-task-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "polly:SynthesizeSpeech"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.tts_cache.arn}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role = aws_iam_role.task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_execution_custom_policy" {
  role = aws_iam_role.task_execution_role.id
  policy_arn = aws_iam_policy.task_execution_custom_policy.arn
}

resource "aws_iam_user" "recording" {
  name = "${var.app_identifier}_recording"
}

resource "aws_iam_access_key" "recording" {
  user = aws_iam_user.recording.name
}

resource "aws_iam_user_policy" "recording" {
  name = aws_iam_user.recording.name
  user = aws_iam_user.recording.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.recording.arn}/*"
    }
  ]
}
EOF
}
