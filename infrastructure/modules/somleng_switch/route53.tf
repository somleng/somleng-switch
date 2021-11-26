resource "aws_route53_record" "switch" {
  zone_id = var.route53_zone.zone_id
  name    = var.switch_subdomain
  type    = "A"

  alias {
    name                   = var.load_balancer.dns_name
    zone_id                = var.load_balancer.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sip" {
  zone_id = var.route53_zone.zone_id
  name    = var.sip_subdomain
  type    = "A"

  alias {
    name                   = var.network_load_balancer.dns_name
    zone_id                = var.network_load_balancer.zone_id
    evaluate_target_health = true
  }
}

