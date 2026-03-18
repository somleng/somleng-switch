resource "aws_security_group" "this" {
  name   = local.security_group_name
  vpc_id = var.vpc.vpc_id
}

resource "aws_security_group_rule" "egress" {
  for_each = toset(["udp", "tcp"])

  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = each.value
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.this.id
}
