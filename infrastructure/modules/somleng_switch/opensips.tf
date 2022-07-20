# resource "aws_iam_role" "opensips_task_role" {
#   name = "${var.app_identifier}-OpenSIPSTaskRole"

#   assume_role_policy = <<EOF
# {
#   "Version": "2008-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": ["ecs-tasks.amazonaws.com"]
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "opensips_task_role_cloudwatch_agent_server_policy" {
#   role = aws_iam_role.ecs_cwagent_daemon_service_task_role.id
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

# resource "aws_iam_role" "opensips_task_execution_role" {
#   name = "${var.app_identifier}-OpenSIPSTaskExecutionRole"

#   assume_role_policy = <<EOF
# {
#   "Version": "2008-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": ["ecs-tasks.amazonaws.com"]
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "opensips_task_execution_role_amazon_ecs_task_execution_role_policy" {
#   role = aws_iam_role.ecs_cwagent_daemon_service_task_execution_role.id
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# # Log Group
# resource "aws_cloudwatch_log_group" "opensips" {
#   name = "${var.app_identifier}-opensips"
#   retention_in_days = 7
# }

# data "template_file" "opensips" {
#   template = file("${path.module}/templates/opensips.json.tpl")

#   vars = {
#     app_image = var.opensips_image

#     opensips_logs_group = aws_cloudwatch_log_group.opensips.name
#     logs_group_region = var.aws_region
#     app_environment = var.app_environment

#     sip_port = var.sip_port
#     freeswitch_event_socket_password_parameter_arn = aws_ssm_parameter.freeswitch_event_socket_password_parameter.arn
#     database_password_parameter_arn = var.db_password_parameter_arn
#     database_name = var.db_name
#     database_username = var.db_username
#     database_host = var.db_host
#     database_port = var.db_port
#   }
# }

# resource "aws_ecs_task_definition" "opensips" {
#   family                   = "${var.app_identifier}-opensips"
#   network_mode             = var.network_mode
#   requires_compatibilities = ["EC2"]
#   task_role_arn = aws_iam_role.opensips_task_role.arn
#   execution_role_arn = aws_iam_role.opensips_task_execution_role.arn
#   container_definitions = data.template_file.container_definitions.rendered
#   memory = data.aws_ec2_instance_type.opensips.memory_size - 256
# }

# resource "aws_ecs_service" "opensips" {
#   name            = aws_ecs_task_definition.opensips.family
#   cluster         = aws_ecs_cluster.cluster.id
#   task_definition = aws_ecs_task_definition.opensips

#   network_configuration {
#     subnets = var.container_instance_subnets
#     security_groups = [
#       aws_security_group.opensips.id,
#       var.db_security_group,
#       aws_security_group.inbound_sip_trunks.id
#     ]
#   }
# }
