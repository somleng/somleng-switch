resource "aws_efs_file_system" "cache" {
  creation_token = var.efs_cache_name
  encrypted      = true

  tags = {
    Name = var.efs_cache_name
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

resource "aws_efs_backup_policy" "cache" {
  file_system_id = aws_efs_file_system.cache.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "cache" {
  for_each = toset(var.vpc.intra_subnets)

  file_system_id  = aws_efs_file_system.cache.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_cache.id]
}

resource "aws_security_group" "efs_cache" {
  name   = "${var.identifier}-efs-cache"
  vpc_id = var.vpc.vpc_id

  tags = {
    Name = "${var.identifier}-cache"
  }
}

resource "aws_security_group_rule" "efs_cache_ingress" {
  type              = "ingress"
  protocol          = "TCP"
  security_group_id = aws_security_group.efs_cache.id
  cidr_blocks       = [var.vpc.vpc_cidr_block]
  from_port         = 2049
  to_port           = 2049
}