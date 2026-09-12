data "aws_ami" "debian_latest" {
  most_recent = true
  name_regex  = "debian-11-arm64"
  owners      = ["136693071363"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "package_builder" {
  name = "package_builder"

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

resource "aws_iam_instance_profile" "package_builder" {
  name = "package_builder"
  role = aws_iam_role.package_builder.name
}

resource "aws_iam_role_policy_attachment" "package_builder_ssm" {
  role       = aws_iam_role.package_builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "package_builder" {
  name_prefix                 = "package-builder"
  image_id                    = data.aws_ami.debian_latest.id
  instance_type               = "t4g.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.package_builder.name
  }

  vpc_security_group_ids = [aws_security_group.package_builder.id]

  user_data = base64encode(join("\n", [
    "#cloud-config",
    yamlencode({
      write_files : [
        {
          path : "/opt/builder/build.sh",
          content : file("${path.module}/templates/build.sh"),
          permissions : "0755",
        },
        {
          path : "/opt/ssm_agent.sh",
          content : file("${path.module}/templates/ssm_agent.sh"),
          permissions : "0755",
        },
      ],
      runcmd : [
        ["/opt/ssm_agent.sh", "/opt/builder/build.sh"]
      ],
    })
  ]))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "package_builder" {
  name   = "package-builder"
  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id
}

resource "aws_security_group_rule" "package_builder_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.package_builder.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_autoscaling_group" "package_builder" {
  name                 = "package-builder"

  launch_template {
    id      = aws_launch_template.package_builder.id
    version = aws_launch_template.package_builder.latest_version
  }

  vpc_zone_identifier = data.terraform_remote_state.core_infrastructure.outputs.vpc.private_subnets

  max_size             = 1
  min_size             = 0
  desired_capacity     = 0
  wait_for_capacity_timeout = 0

  tag {
    key                 = "Name"
    value               = "package-builder"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
