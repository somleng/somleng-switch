resource "aws_security_group_rule" "healthcheck" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "tcp"
  from_port         = var.sip_port
  security_group_id = module.container_instances.security_group.id
  cidr_blocks       = data.aws_ip_ranges.route53_healthchecks.cidr_blocks
}

resource "aws_security_group_rule" "sip" {
  type              = "ingress"
  to_port           = var.sip_port
  protocol          = "udp"
  from_port         = var.sip_port
  security_group_id = module.container_instances.security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "icmp" {
  type              = "ingress"
  to_port           = -1
  protocol          = "icmp"
  from_port         = -1
  security_group_id = module.container_instances.security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}
