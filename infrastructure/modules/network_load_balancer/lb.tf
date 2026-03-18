resource "aws_lb" "this" {
  name                             = var.identifier
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true

  security_groups = [aws_security_group.this.id]

  access_logs {
    bucket  = var.logs_bucket.id
    prefix  = var.identifier
    enabled = true
  }

  dynamic "subnet_mapping" {
    for_each = var.vpc.public_subnets
    content {
      subnet_id     = subnet_mapping.value
      allocation_id = aws_eip.this.*.id[subnet_mapping.key]
    }
  }
}
