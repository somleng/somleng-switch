locals {
  create_default_lb_rule = var.lb_default_rule_index != null
}

resource "aws_lb_target_group" "regional" {
  name                 = "${var.identifier}-${var.region_alias}"
  port                 = var.webserver_port
  protocol             = "HTTP"
  vpc_id               = var.default_vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    protocol          = "HTTP"
    path              = "/health_checks"
    healthy_threshold = 3
    interval          = 10
  }

  provider = aws.default
}

resource "aws_lb_target_group" "default" {
  count                = local.create_default_lb_rule ? 1 : 0
  name                 = "${var.identifier}-internal"
  port                 = var.webserver_port
  protocol             = "HTTP"
  vpc_id               = var.default_vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    protocol          = "HTTP"
    path              = "/health_checks"
    healthy_threshold = 3
    interval          = 10
  }

  provider = aws.default
}

resource "aws_lb_listener_rule" "regional" {
  priority     = var.lb_region_rule_index
  listener_arn = var.internal_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.regional.id
  }

  condition {
    host_header {
      values = [local.route53_record.fqdn]
    }
  }

  condition {
    http_header {
      http_header_name = "X-Somleng-Region-Alias"
      values           = [var.region_alias]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }

  provider = aws.default
}

resource "aws_lb_listener_rule" "default" {
  count        = local.create_default_lb_rule ? 1 : 0
  priority     = var.lb_default_rule_index
  listener_arn = var.internal_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default[0].id
  }

  condition {
    host_header {
      values = [local.route53_record.fqdn]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }

  provider = aws.default
}
