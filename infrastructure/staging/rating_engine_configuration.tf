module "rating_engine_configuration" {
  source = "../modules/rating_engine_configuration"

  identifier                = var.rating_engine_identifier
  image                     = data.terraform_remote_state.core.outputs.rating_engine_ecr_repository.this.repository_url
  stordb_password_parameter = data.terraform_remote_state.core_infrastructure.outputs.db_staging.master_password_parameter
  stordb_dbname             = "cgrates_staging"
  stordb_host               = data.terraform_remote_state.core_infrastructure.outputs.db_staging.this.endpoint
  stordb_port               = data.terraform_remote_state.core_infrastructure.outputs.db_staging.this.port
  stordb_user               = data.terraform_remote_state.core_infrastructure.outputs.db_staging.this.master_username
  datadb_cache              = module.redis
}
