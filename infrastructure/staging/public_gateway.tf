module "public_gateway" {
  source = "../modules/public_gateway"

  identifier      = var.public_gateway_identifier
  app_environment = var.app_environment

  aws_region = var.aws_default_region
  vpc        = data.terraform_remote_state.core_infrastructure.outputs.vpc

  ecs_cluster = aws_ecs_cluster.this

  app_image       = data.terraform_remote_state.core.outputs.public_gateway_ecr_repository.repository_uri
  scheduler_image = data.terraform_remote_state.core.outputs.opensips_scheduler_ecr_repository.repository_uri
  min_tasks       = 0
  max_tasks       = 2

  sip_port             = var.sip_port
  sip_alternative_port = var.sip_alternative_port

  db_security_group     = data.terraform_remote_state.core_infrastructure.outputs.db_security_group
  db_password_parameter = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter
  db_name               = var.public_gateway_db_name
  db_username           = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_host               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  global_accelerator    = data.terraform_remote_state.core_infrastructure.outputs.global_accelerator
  logs_bucket           = data.terraform_remote_state.core_infrastructure.outputs.logs_bucket
}
