# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
# https://aws.amazon.com/ec2/instance-types/t4/
data "aws_ssm_parameter" "container_instance" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended"
}

resource "aws_iam_role" "container_instance" {
  name = "${var.app_identifier}_ecs_container_instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "container_instance" {
  name = "${var.app_identifier}_ecs_container_instance_profile"
  role = aws_iam_role.container_instance.name
}

resource "aws_iam_role_policy_attachment" "container_instance_ecs" {
  role = aws_iam_role.container_instance.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "container_instance_ecs_ec2_role" {
  role = aws_iam_role.container_instance.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "container_instance_ssm" {
  role       = aws_iam_role.container_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_launch_configuration" "container_instance" {
  name                        = "${var.app_identifier}-container-instance"
  image_id                    = jsondecode(data.aws_ssm_parameter.container_instance.value).image_id
  instance_type               = "t4g.small"
  iam_instance_profile        = aws_iam_instance_profile.container_instance.name
  security_groups             = [aws_security_group.container_instance.id]
  user_data                   = data.template_file.container_instance_user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "container_instance" {
  name   = "${var.app_identifier}-container-instance"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "container_instance_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.container_instance.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_autoscaling_group" "container_instance" {
  name                 = var.app_identifier
  launch_configuration = aws_launch_configuration.container_instance.name
  vpc_zone_identifier  = var.container_instance_subnets
  max_size             = 10
  min_size             = 0
  desired_capacity     = 0
  wait_for_capacity_timeout = 0
  protect_from_scale_in = true

  tag {
    key                 = "Name"
    value               = var.app_identifier
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

data "template_file" "container_instance_user_data" {
  template = file("${path.module}/templates/container_instance_user_data.sh")

  vars = {
    cluster_name = var.ecs_cluster.name
  }
}
