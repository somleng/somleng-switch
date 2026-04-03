# Security Group Rules

resource "aws_security_group_rule" "nlb_sip_ingress" {
  type        = "ingress"
  from_port   = var.sip_port
  to_port     = var.sip_port
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = var.load_balancer.security_group.id
}

resource "aws_security_group_rule" "nlb_sip_alternative_ingress" {
  type        = "ingress"
  from_port   = var.sip_alternative_port
  to_port     = var.sip_alternative_port
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = var.load_balancer.security_group.id
}

# Target Groups

resource "aws_lb_target_group" "sip" {
  name        = "${var.identifier}-sip"
  port        = var.sip_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc.vpc_id

  connection_termination = true

  health_check {
    protocol          = "TCP"
    port              = var.sip_port
    healthy_threshold = 3
    interval          = 10
  }
}

resource "aws_lb_listener" "sip" {
  load_balancer_arn = var.load_balancer.this.arn
  port              = var.sip_port
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sip.arn
  }
}

resource "aws_lb_target_group" "sip_alternative" {
  name        = "${var.identifier}-sip-alt"
  port        = var.sip_alternative_port
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc.vpc_id

  connection_termination = true

  health_check {
    protocol          = "TCP"
    port              = var.sip_port
    healthy_threshold = 3
    interval          = 10
  }
}

resource "aws_lb_listener" "sip_alternative" {
  load_balancer_arn = var.load_balancer.this.arn
  port              = var.sip_alternative_port
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sip_alternative.arn
  }
}
