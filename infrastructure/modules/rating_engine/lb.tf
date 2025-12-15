locals {
  subdomain         = var.identifier
  target_group_name = var.identifier
}

resource "aws_lb_target_group" "this" {
  name                 = local.target_group_name
  port                 = var.http_port
  protocol             = "HTTP"
  vpc_id               = var.region.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    protocol          = "HTTP"
    path              = "/health_checks"
    healthy_threshold = 3
    interval          = 10
  }
}

resource "aws_lb_listener_rule" "this" {
  priority     = var.lb_rule_index
  listener_arn = var.region.internal_load_balancer.https_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    host_header {
      values = [aws_route53_record.this.fqdn]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}
