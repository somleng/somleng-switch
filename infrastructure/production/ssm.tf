data "aws_ssm_parameter" "call_platform_password" {
  name = "somleng.${var.app_environment}.services_password"
}

data "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name = "somleng-switch.production.freeswitch_event_socket_password"
}
