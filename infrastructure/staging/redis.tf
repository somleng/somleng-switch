module "redis" {
  source = "../modules/redis"

  identifier = "switch-staging"
  vpc        = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc
}
