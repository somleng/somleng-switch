# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
# https://aws.amazon.com/ec2/instance-types/t4/
data "aws_ssm_parameter" "container_instance_arm64" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended"
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
data "aws_ssm_parameter" "container_instance" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "container_instance" {
  name_prefix                 = var.app_identifier
  image_id                    = jsondecode(data.aws_ssm_parameter.container_instance.value).image_id
  instance_type               = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.container_instance.name
  }

  vpc_security_group_ids = [aws_security_group.container_instance.id]

  user_data = base64encode(join("\n", [
    "#cloud-config",
    yamlencode({
      # https://cloudinit.readthedocs.io/en/latest/topics/modules.html
      write_files : [
        {
          path : "/opt/setup.sh",
          content : templatefile("${path.module}/templates/container_instances/setup.sh", { cluster_name = local.cluster_name }),
          permissions : "0755",
        },
      ],
      runcmd : [
        ["/opt/setup.sh"]
      ],
    })
  ]))

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

  launch_template {
    id      = aws_launch_template.container_instance.id
    version = aws_launch_template.container_instance.latest_version
  }

  vpc_zone_identifier  = var.container_instance_subnets
  max_size             = 10
  min_size             = 0
  desired_capacity     = 0
  wait_for_capacity_timeout = 0
  protect_from_scale_in = var.scale_in_protection

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

  lifecycle {
    ignore_changes = [desired_capacity]
    create_before_destroy = true
  }
}

# Automatically update the SSM agent

# https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-state-cli.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association
resource "aws_ssm_association" "update_ssm_agent" {
  name = "AWS-UpdateSSMAgent"

  targets {
    key    = "tag:Name"
    values = [var.app_identifier]
  }

  schedule_expression = "cron(0 19 ? * SAT *)"
}
