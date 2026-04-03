resource "aws_globalaccelerator_listener" "this" {
  accelerator_arn = var.global_accelerator.id
  protocol        = "UDP"

  port_range {
    from_port = var.sip_port
    to_port   = var.sip_port
  }

  port_range {
    from_port = var.sip_alternative_port
    to_port   = var.sip_alternative_port
  }
}

resource "aws_globalaccelerator_endpoint_group" "public_gateway" {
  listener_arn = aws_globalaccelerator_listener.this.id

  endpoint_configuration {
    endpoint_id                    = var.load_balancer.this.arn
    client_ip_preservation_enabled = true
  }
}
