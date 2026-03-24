module "rating_engine" {
  source = "../modules/rating_engine"

  internal_route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
  region                = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region
  ecs_cluster           = aws_ecs_cluster.this
  identifier            = var.rating_engine_identifier
  app_environment       = var.app_environment

  configuration = module.rating_engine_configuration

  lb_rule_index = 150

  min_tasks = 0
}
