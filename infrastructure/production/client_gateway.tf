module "client_gateway" {
  source = "../modules/client_gateway"

  subdomain = "sip"

  identifier      = var.client_gateway_identifier
  app_environment = var.app_environment

  aws_region   = var.aws_region
  vpc          = data.terraform_remote_state.core_infrastructure.outputs.vpc
  ecs_cluster  = aws_ecs_cluster.this
  route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_somleng_org

  app_image       = data.terraform_remote_state.core.outputs.client_gateway_ecr_repository.repository_uri
  scheduler_image = data.terraform_remote_state.core.outputs.opensips_scheduler_ecr_repository.repository_uri

  db_security_group = data.terraform_remote_state.core_infrastructure.outputs.db_security_group
  sip_port          = var.sip_port

  db_password_parameter = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter
  db_name               = var.client_gateway_db_name
  db_username           = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_host               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  services_function     = module.services.function
}
