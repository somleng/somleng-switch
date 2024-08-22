resource "aws_route53_record" "this" {
  zone_id = var.internal_route53_zone.zone_id
  name    = var.subdomain
  type    = "A"

  alias {
    name                   = var.internal_load_balancer.dns_name
    zone_id                = var.internal_load_balancer.zone_id
    evaluate_target_health = true
  }
}
