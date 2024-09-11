locals {
  security_group_name = var.security_group_name == null ? var.name : var.security_group_name
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(var.vpc.intra_subnets)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.this.id]
}

resource "aws_security_group" "this" {
  name   = local.security_group_name
  vpc_id = var.vpc.vpc_id

  tags = {
    Name = local.security_group_name
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  protocol          = "TCP"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = [var.vpc.vpc_cidr_block]
  from_port         = 2049
  to_port           = 2049
}
