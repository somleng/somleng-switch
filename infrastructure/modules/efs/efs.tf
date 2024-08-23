locals {
  create_efs_file_system = var.file_system == null
  efs_file_system        = local.create_efs_file_system ? aws_efs_file_system.this[0] : var.file_system
}

resource "aws_efs_file_system" "this" {
  count          = local.create_efs_file_system ? 1 : 0
  creation_token = var.name
  encrypted      = true

  tags = {
    Name = var.name
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

resource "aws_efs_backup_policy" "this" {
  count = local.create_efs_file_system ? 1 : 0

  file_system_id = aws_efs_file_system.this[0].id

  backup_policy {
    status = "DISABLED"
  }
}
