# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-ECS-instancelevel.html#deploy-container-insights-ECS-instancelevel-manual

# IAM Roles
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-ECS-instancelevel.html#deploy-container-insights-ECS-instancelevel-IAMRoles
resource "aws_iam_role" "ecs_cwagent_daemon_service_task_role" {
  name = "${var.app_identifier}-CWAgentECSTaskRole"

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

# Used by the CloudWatch agent to publish metrics
resource "aws_iam_role_policy_attachment" "ecs_cwagent_daemon_service_task_role_cloudwatch_agent_server_policy" {
  role = aws_iam_role.ecs_cwagent_daemon_service_task_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role" "ecs_cwagent_daemon_service_task_execution_role" {
  name = "${var.app_identifier}-CWAgentECSExecutionRole"

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

# Used by Amazon ECS agent to launch the CloudWatch agent
resource "aws_iam_role_policy_attachment" "ecs_cwagent_daemon_service_task_execution_role_cloudwatch_agent_server_policy" {
  role = aws_iam_role.ecs_cwagent_daemon_service_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_cwagent_daemon_service_task_execution_role_amazon_ecs_task_execution_role_policy" {
  role = aws_iam_role.ecs_cwagent_daemon_service_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Log Group
resource "aws_cloudwatch_log_group" "ecs_cwagent_daemon_service" {
  name = "/ecs/ecs-cwagent-daemon-service/${var.app_identifier}"
  retention_in_days = 7
}

# ECS Service
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-ECS-instancelevel.html#deploy-container-insights-ECS-instancelevel-taskdefinition
# https://github.com/aws-samples/amazon-cloudwatch-container-insights/blob/master/ecs-task-definition-templates/deployment-mode/daemon-service/cwagent-ecs-instance-metric/cwagent-ecs-instance-metric.json
resource "aws_ecs_task_definition" "ecs_cwagent_daemon_service" {
  family                   = "ecs-cwagent-daemon-service-${var.app_identifier}"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  task_role_arn = aws_iam_role.ecs_cwagent_daemon_service_task_role.arn
  execution_role_arn = aws_iam_role.ecs_cwagent_daemon_service_task_execution_role.arn

  cpu = 128
  memory = 64

  container_definitions    = <<CONTAINER_DEFINITIONS
[
  {
    "name": "cloudwatch-agent",
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

resource "aws_ecs_service" "ecs_cwagent_daemon_service" {
  count = var.container_insights_enabled ? 1 : 0

  name            = aws_ecs_task_definition.ecs_cwagent_daemon_service.family
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.ecs_cwagent_daemon_service.arn
  scheduling_strategy = "DAEMON"
}
