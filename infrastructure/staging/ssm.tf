data "aws_ssm_parameter" "somleng_services_password" {
  name = "somleng.staging.services_password"
}

data "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name = "somleng-switch.staging.freeswitch_event_socket_password"
}
