resource "aws_security_group" "app" {
  name   = "${var.app_identifier}-app"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "app_ingress" {
  type              = "ingress"
  to_port           = 80
  protocol          = "TCP"
  from_port         = 80
  security_group_id = aws_security_group.app.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.app.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "worker" {
  name   = "${var.app_identifier}-worker"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.worker.id
  cidr_blocks = ["0.0.0.0/0"]
}
