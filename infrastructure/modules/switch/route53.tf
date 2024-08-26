resource "aws_route53_record" "this" {
  zone_id = var.internal_route53_zone.zone_id
  name    = local.subdomain
  type    = "A"

  alias {
    name                   = var.region.internal_load_balancer.this.dns_name
    zone_id                = var.region.internal_load_balancer.this.zone_id
    evaluate_target_health = true
  }
}
