resource "aws_security_group" "this" {
  name   = var.identifier
  vpc_id = var.vpc.vpc_id
}

resource "aws_security_group_rule" "healthcheck" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "tcp"
  from_port         = var.sip_port
  security_group_id = aws_security_group.this.id
  cidr_blocks       = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "udp"
  from_port         = var.sip_port
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sip_alternative" {
  type              = "ingress"
  to_port           = var.sip_alternative_port
  protocol          = "udp"
  from_port         = var.sip_alternative_port
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
