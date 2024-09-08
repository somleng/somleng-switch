resource "aws_security_group" "this" {
  name   = var.identifier
  vpc_id = var.region.vpc.vpc_id

  tags = {
    "Name" = var.identifier
  }
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  to_port           = var.webserver_port
  protocol          = "TCP"
  from_port         = var.webserver_port
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_freeswitch_event_socket" {
  type              = "ingress"
  to_port           = 8021
  protocol          = "TCP"
  from_port         = 8021
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "UDP"
  from_port         = var.sip_port
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_sip_alternative" {
  type              = "ingress"
  to_port           = var.sip_alternative_port
  protocol          = "UDP"
  from_port         = var.sip_alternative_port
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "icmp" {
  type              = "ingress"
  to_port           = -1
  protocol          = "icmp"
  from_port         = -1
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}
