locals {
  create_default_lb_rule = var.lb_default_rule_index != null
  create_region_lb_rule  = var.lb_region_rule_index != null
}

resource "aws_lb_target_group" "this" {
  name                 = "${var.identifier}-internal"
  port                 = var.webserver_port
  protocol             = "HTTP"
  vpc_id               = var.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    protocol          = "HTTP"
    path              = "/health_checks"
    healthy_threshold = 3
    interval          = 10
  }
}

resource "aws_lb_listener_rule" "region" {
  count        = local.create_region_lb_rule ? 1 : 0
  priority     = var.lb_region_rule_index
  listener_arn = var.internal_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    host_header {
      values = [local.route53_record.fqdn]
    }

    http_header {
      http_header_name = "X-Somleng-Region-Alias"
      values           = [var.region_alias]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_listener_rule" "default" {
  count        = local.create_default_lb_rule ? 1 : 0
  priority     = var.lb_default_rule_index
  listener_arn = var.internal_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    host_header {
      values = [local.route53_record.fqdn]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}
