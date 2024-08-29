locals {
  create_iam_task_role           = var.iam_task_role == null
  create_iam_task_execution_role = var.iam_task_execution_role == null
  iam_task_role                  = local.create_iam_task_role ? aws_iam_role.ecs_task_role[0] : var.iam_task_role
  iam_task_execution_role        = local.create_iam_task_execution_role ? aws_iam_role.task_execution_role[0] : var.iam_task_execution_role
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ECS Task Role

resource "aws_iam_role" "ecs_task_role" {
  count              = local.create_iam_task_role ? 1 : 0
  name               = "${var.identifier}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    effect    = "Allow"
    actions   = ["polly:DescribeVoices", "polly:SynthesizeSpeech"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [var.services_function.this.arn]
  }
}

resource "aws_iam_policy" "ecs_task_policy" {
  count = local.create_iam_task_role ? 1 : 0
  name  = "${var.identifier}-ecs-task-policy"

  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_custom_policy" {
  count      = local.create_iam_task_role ? 1 : 0
  role       = aws_iam_role.ecs_task_role[0].id
  policy_arn = aws_iam_policy.ecs_task_policy[0].arn
}

# ECS Task Execution Role

resource "aws_iam_role" "task_execution_role" {
  count              = local.create_iam_task_execution_role ? 1 : 0
  name               = "${var.identifier}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "task_execution_policy" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameters"]
    resources = [
      local.application_master_key_parameter.arn,
      local.rayo_password_parameter.arn,
      local.freeswitch_event_socket_password_parameter.arn,
      var.json_cdr_password_parameter.arn,
      local.recordings_bucket_access_key_id_parameter.arn,
      local.recordings_bucket_secret_access_key_parameter.arn
    ]
  }
}

resource "aws_iam_policy" "task_execution_custom_policy" {
  count = local.create_iam_task_execution_role ? 1 : 0
  name  = "${var.identifier}-task-execution-custom-policy"

  policy = data.aws_iam_policy_document.task_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "task_execution_custom_policy" {
  count      = local.create_iam_task_execution_role ? 1 : 0
  role       = aws_iam_role.task_execution_role[0].id
  policy_arn = aws_iam_policy.task_execution_custom_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  count      = local.create_iam_task_execution_role ? 1 : 0
  role       = aws_iam_role.task_execution_role[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
