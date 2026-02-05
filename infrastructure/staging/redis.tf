module "redis" {
  source = "../modules/redis"

  identifier                 = "switch-staging"
  vpc                        = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc
  node_type                  = "cache.t4g.micro"
  automatic_failover_enabled = false
  num_cache_clusters         = 1
}
