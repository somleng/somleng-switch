module "rating_engine" {
  source = "../modules/rating_engine"


  internal_route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
  region                = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region
  ecs_cluster           = aws_ecs_cluster.this
  identifier            = var.rating_engine_identifier
  app_environment       = var.app_environment

  app_image = data.terraform_remote_state.core.outputs.rating_engine_server_ecr_repository.this.repository_url

  stordb_dbname                 = "cgrates_staging"
  stordb_user                   = data.terraform_remote_state.core_infrastructure.outputs.db_staging.this.master_username
  stordb_host                   = data.terraform_remote_state.core_infrastructure.outputs.db_staging.this.endpoint
  stordb_port                   = data.terraform_remote_state.core_infrastructure.outputs.db_staging.this.port
  stordb_password_parameter_arn = data.terraform_remote_state.core_infrastructure.outputs.db_staging.master_password_parameter.arn
  stordb_security_group         = data.terraform_remote_state.core_infrastructure.outputs.db_staging.security_group.id
  datadb_cache                  = module.redis

  lb_rule_index = 150

  min_tasks = 0
}
