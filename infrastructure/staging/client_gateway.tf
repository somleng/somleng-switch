module "client_gateway" {
  source = "../modules/client_gateway"

  subdomain = "sip-staging"

  identifier      = var.client_gateway_identifier
  app_environment = var.app_environment

  aws_region   = var.aws_default_region
  vpc          = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc
  ecs_cluster  = aws_ecs_cluster.this
  route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_somleng_org

  app_image       = data.terraform_remote_state.core.outputs.client_gateway_ecr_repository.this.repository_url
  scheduler_image = data.terraform_remote_state.core.outputs.gateway_scheduler_ecr_repository.this.repository_url
  min_tasks       = 0
  max_tasks       = 2

  db_security_group = data.terraform_remote_state.core_infrastructure.outputs.db_security_group
  assign_eips       = false
  sip_port          = var.sip_port

  db_password_parameter = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter
  db_name               = var.client_gateway_db_name
  db_username           = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_host               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  services_function     = module.services
}
