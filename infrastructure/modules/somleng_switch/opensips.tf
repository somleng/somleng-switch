resource "aws_iam_role" "opensips_task_role" {
  name = "${var.app_identifier}-OpenSIPSTaskRole"

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

resource "aws_iam_role_policy_attachment" "opensips_task_role_cloudwatch_agent_server_policy" {
  role = aws_iam_role.ecs_cwagent_daemon_service_task_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role" "opensips_task_execution_role" {
  name = "${var.app_identifier}-OpenSIPSTaskExecutionRole"

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

resource "aws_iam_role_policy_attachment" "opensips_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role = aws_iam_role.ecs_cwagent_daemon_service_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Group
resource "aws_cloudwatch_log_group" "opensips" {
  name = "${var.app_identifier}-opensips"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "opensips" {
  family                   = "${var.app_identifier}-opensips"
  network_mode             = var.network_mode
  requires_compatibilities = ["EC2"]
  task_role_arn = aws_iam_role.opensips_task_role.arn
  execution_role_arn = aws_iam_role.opensips_task_execution_role.arn

  memory = data.aws_ec2_instance_type.opensips.memory_size - 256

  container_definitions    = <<CONTAINER_DEFINITIONS
[
  {
    "name": "opensips",
    "image": "amazon/cloudwatch-agent:latest",
    "mountPoints": [
      {
        "readOnly": true,
        "containerPath": "/rootfs/proc",
        "sourceVolume": "proc"
      },
      {
        "readOnly": true,
        "containerPath": "/rootfs/dev",
        "sourceVolume": "dev"
      },
      {
        "readOnly": true,
        "containerPath": "/sys/fs/cgroup",
        "sourceVolume": "al2_cgroup"
      },
      {
        "readOnly": true,
        "containerPath": "/cgroup",
        "sourceVolume": "al1_cgroup"
      },
      {
        "readOnly": true,
        "containerPath": "/rootfs/sys/fs/cgroup",
        "sourceVolume": "al2_cgroup"
      },
      {
        "readOnly": true,
        "containerPath": "/rootfs/cgroup",
        "sourceVolume": "al1_cgroup"
      }
    ],
    "environment": [
      {
        "name": "CW_CONFIG_CONTENT",
        "value": "{\"logs\":{\"metrics_collected\":{\"ecs\":{\"metrics_collection_interval\":1}}}}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group": "True",
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_cwagent_daemon_service.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
CONTAINER_DEFINITIONS

  volume {
    name = "proc"
    host_path = "/proc"
  }

  volume {
    name = "dev"
    host_path = "/dev"
  }

  volume {
    name = "al1_cgroup"
    host_path = "/cgroup"
  }

  volume {
    name = "al2_cgroup"
    host_path = "/sys/fs/cgroup"
  }
}

resource "aws_ecs_service" "opensips" {
  name            = aws_ecs_task_definition.opensips.family
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.opensips

  network_configuration {
    subnets = var.container_instance_subnets
    security_groups = [
      aws_security_group.opensips.id,
      var.db_security_group,
      aws_security_group.inbound_sip_trunks.id
    ]
  }
}
