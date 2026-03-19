data "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name = "somleng-switch.staging.freeswitch_event_socket_password"
}

data "aws_ssm_parameter" "call_platform_password" {
  name = "somleng.${var.app_environment}.services_password"
}

resource "aws_ssm_parameter" "rating_engine_http_password" {
  name  = "${var.rating_engine_identifier}.http_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}
