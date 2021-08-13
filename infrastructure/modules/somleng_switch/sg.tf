data "aws_security_group" "inbound_sip_trunks" {
  filter {
    name   = "group-name"
    values = [var.inbound_sip_trunks_security_group_name]
  }
}

resource "aws_security_group" "appserver" {
  name   = "${var.app_identifier}-appserver"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "appserver_ingress" {
  type              = "ingress"
  to_port           = var.webserver_container_port
  protocol          = "TCP"
  from_port         = var.webserver_container_port
  security_group_id = aws_security_group.appserver.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "appserver_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.appserver.id
  cidr_blocks = ["0.0.0.0/0"]
}
