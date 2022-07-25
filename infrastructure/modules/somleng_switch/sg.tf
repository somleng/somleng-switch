resource "aws_security_group" "switch" {
  name   = "${var.app_identifier}-appserver"
  vpc_id = var.vpc_id

  tags = {
    "Name" = "${var.app_identifier}-switch"
  }
}

resource "aws_security_group_rule" "switch_ingress_http" {
  type              = "ingress"
  to_port           = var.webserver_container_port
  protocol          = "TCP"
  from_port         = var.webserver_container_port
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "switch_ingress_freeswitch_event_socket" {
  type              = "ingress"
  to_port           = 8021
  protocol          = "TCP"
  from_port         = 8021
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "switch_ingress_sip" {
  type              = "ingress"
  to_port           = 5060
  protocol          = "UDP"
  from_port         = 5060
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "switch_ingress_sip_alternative" {
  type              = "ingress"
  to_port           = 5080
  protocol          = "UDP"
  from_port         = 5080
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "switch_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.switch.id
  cidr_blocks = ["0.0.0.0/0"]
}
