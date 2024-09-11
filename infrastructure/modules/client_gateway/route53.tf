resource "aws_route53_health_check" "client_gateway" {
  for_each = { for index, eip in aws_eip.client_gateway : index => eip }

  reference_name   = "${var.subdomain}-${each.key + 1}"
  ip_address       = each.value.public_ip
  port             = var.sip_port
  type             = "TCP"
  request_interval = 30

  tags = {
    Name = "${var.subdomain}-${each.key + 1}"
  }
}

resource "aws_route53_record" "client_gateway" {
  for_each = aws_route53_health_check.client_gateway
  zone_id  = var.route53_zone.zone_id
  name     = var.subdomain
  type     = "A"
  ttl      = 300
  records  = [each.value.ip_address]

  multivalue_answer_routing_policy = true
  set_identifier                   = "${var.identifier}-${each.key + 1}"
  health_check_id                  = each.value.id
}

resource "aws_lambda_invocation" "create_domain" {
  for_each      = aws_route53_record.client_gateway
  function_name = var.services_function.this.function_name

  input = jsonencode({
    serviceAction = "CreateDomain",
    parameters = {
      domain = each.value.fqdn
    }
  })
}
