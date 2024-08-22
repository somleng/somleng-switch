resource "aws_lb_target_group" "http" {
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

resource "aws_lb_listener_rule" "http" {
  priority = var.app_environment == "production" ? 20 : 120

  listener_arn = var.internal_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.id
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
