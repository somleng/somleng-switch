locals {
  create_route53_record = var.route53_record == null
  route53_record        = local.create_route53_record ? aws_route53_record.this[0] : var.route53_record
}

resource "aws_route53_record" "this" {
  count   = local.create_route53_record ? 1 : 0
  zone_id = var.internal_route53_zone.zone_id
  name    = var.subdomain
  type    = "A"

  alias {
    name                   = var.internal_load_balancer.dns_name
    zone_id                = var.internal_load_balancer.zone_id
    evaluate_target_health = true
  }
}
