locals {
  create_iam_role      = var.iam_instance_profile == null
  iam_instance_profile = local.create_iam_role ? aws_iam_instance_profile.this[0] : var.iam_instance_profile
}

data "aws_iam_role" "this" {
  name = local.iam_instance_profile.role
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  count = local.create_iam_role ? 1 : 0
  name  = "${var.app_identifier}_ecs_container_instance_role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "this" {
  count = local.create_iam_role ? 1 : 0
  name  = "${var.app_identifier}_ecs_container_instance_profile"
  role  = aws_iam_role.this[0].name
}

resource "aws_iam_role_policy_attachment" "ecs" {
  count      = local.create_iam_role ? 1 : 0
  role       = aws_iam_role.this[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  count      = local.create_iam_role ? 1 : 0
  role       = aws_iam_role.this[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = local.create_iam_role ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
