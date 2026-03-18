module "public_gateway_nlb" {
  source      = "../modules/network_load_balancer"
  identifier  = "public-gateway"
  vpc         = local.region.vpc
  logs_bucket = local.region.logs_bucket
}
