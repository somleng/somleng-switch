module "redis" {
  source = "../modules/redis"

  identifier = "switch"
  vpc        = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc
}
