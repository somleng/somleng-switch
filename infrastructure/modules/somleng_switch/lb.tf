resource "aws_lb_target_group" "this" {
  name = var.app_identifier
  port = var.webserver_container_port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"
  deregistration_delay = 60

  health_check {
    protocol = "HTTP"
    path = "/health_checks"
    healthy_threshold = 3
    interval = 10
  }
}

resource "aws_lb_listener_rule" "this" {
  priority = 20

  listener_arn = var.listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    host_header {
      values = ["ahn.somleng.org"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_target_group" "sip" {
  name        = "${var.app_identifier}-sip"
  port        = var.sip_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # https://github.com/hashicorp/terraform-provider-aws/issues/17227
  # connection_termination = true

  health_check {
    protocol = "HTTP"
    port = var.webserver_container_port
    path = "/health_checks/freeswitch"
    healthy_threshold = 3
    interval = 10
  }
}

resource "aws_lb_listener" "sip" {
  load_balancer_arn = var.network_load_balancer_arn
  port              = var.sip_port
  protocol          = "UDP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.sip.arn
  }
}
