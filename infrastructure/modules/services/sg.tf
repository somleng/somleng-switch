resource "aws_security_group" "this" {
  name   = var.identifier
  vpc_id = var.vpc.vpc_id

  tags = {
    "Name" = var.identifier
  }
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.this.id
  cidr_blocks       = ["0.0.0.0/0"]
}
