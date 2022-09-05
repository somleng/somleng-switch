data "aws_ip_ranges" "route53_healthchecks" {
  services = ["route53_healthchecks"]
}
