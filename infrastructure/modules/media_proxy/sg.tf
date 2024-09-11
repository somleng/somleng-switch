resource "aws_security_group_rule" "control" {
  type              = "ingress"
  to_port           = var.ng_port
  protocol          = "udp"
  from_port         = var.ng_port
  security_group_id = module.container_instances.security_group.id
  cidr_blocks       = [var.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "media" {
  type              = "ingress"
  to_port           = var.media_port_max
  protocol          = "udp"
  from_port         = var.media_port_min
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
