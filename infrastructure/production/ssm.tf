data "aws_ssm_parameter" "somleng_services_password" {
  name = "somleng.production.services_password"
}

data "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name = "somleng-switch.production.freeswitch_event_socket_password"
}
