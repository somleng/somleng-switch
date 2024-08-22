resource "aws_security_group" "nlb" {
  name   = "${var.identifier}-nlb"
  vpc_id = var.vpc.vpc_id
}

resource "aws_security_group_rule" "nlb_sip_ingress" {
  type        = "ingress"
  from_port   = var.sip_port
  to_port     = var.sip_port
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nlb.id
}

resource "aws_security_group_rule" "nlb_sip_alternative_ingress" {
  type        = "ingress"
  from_port   = var.sip_alternative_port
  to_port     = var.sip_alternative_port
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nlb.id
}

resource "aws_security_group_rule" "nlb_udp_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nlb.id
}

resource "aws_security_group_rule" "nlb_tcp_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nlb.id
}

resource "aws_eip" "public_gateway_nlb" {
  count  = var.min_tasks > 0 ? length(var.vpc.public_subnets) : 0
  domain = "vpc"

  tags = {
    Name = "Public Gateway NLB IP"
  }
}

resource "aws_lb" "public_gateway_nlb" {
  count                            = var.min_tasks > 0 ? 1 : 0
  name                             = var.identifier
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true

  security_groups = [aws_security_group.nlb.id]

  access_logs {
    bucket  = var.logs_bucket.id
    prefix  = var.identifier
    enabled = true
  }

  dynamic "subnet_mapping" {
    for_each = var.vpc.public_subnets
    content {
      subnet_id     = subnet_mapping.value
      allocation_id = aws_eip.public_gateway_nlb.*.id[subnet_mapping.key]
    }
  }
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
  count             = var.min_tasks > 0 ? 1 : 0
  load_balancer_arn = aws_lb.public_gateway_nlb[count.index].arn
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
  count             = var.min_tasks > 0 ? 1 : 0
  load_balancer_arn = aws_lb.public_gateway_nlb[count.index].arn
  port              = var.sip_alternative_port
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sip_alternative.arn
  }
}
