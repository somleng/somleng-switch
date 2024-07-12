data "aws_ssm_parameter" "arm64_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

data "archive_file" "test_files" {
  type        = "zip"
  source_dir  = "${path.module}/tests"
  output_path = "${path.module}/tests_files.zip"
}

resource "aws_security_group" "this" {
  name   = "somleng-switch-testing"
  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "this" {
  ami           = data.aws_ssm_parameter.arm64_ami.value
  instance_type = "t4g.small"
  security_groups = [
    aws_security_group.this.id,
  ]
  subnet_id                   = element(data.terraform_remote_state.core_infrastructure.outputs.vpc.public_subnets, 0)
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.this.id

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name = "somleng-switch-testing"
  }

  user_data = base64encode(join("\n", [
    "#cloud-config",
    yamlencode({
      # https://cloudinit.readthedocs.io/en/latest/topics/modules.html
      write_files : [
        {
          path : "/opt/testing/setup.sh",
          content : file("${path.module}/setup.sh"),
          permissions : "0755",
        },
        {
          path : "/opt/testing/Dockerfile",
          content : file("${path.module}/Dockerfile"),
        },
        {
          encoding : "b64",
          path : "/opt/testing/test_files.zip",
          content : filebase64(data.archive_file.test_files.output_path),
        },
      ],
      runcmd : [
        ["/opt/testing/setup.sh"]
      ],
    })
  ]))
}

resource "aws_iam_role" "this" {
  name = "somleng-switch-testing"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = aws_iam_role.this.name
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
