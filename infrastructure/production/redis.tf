module "redis" {
  source = "../modules/redis"

  identifier                 = "switch"
  vpc                        = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc
  node_type                  = "cache.t4g.small"
  automatic_failover_enabled = true
  num_cache_clusters         = 2
}
