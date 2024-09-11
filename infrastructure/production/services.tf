module "services" {
  source = "../modules/services"

  identifier             = var.services_identifier
  app_environment        = var.app_environment
  switch_group           = var.switch_identifier
  media_proxy_group      = var.media_proxy_identifier
  client_gateway_group   = var.client_gateway_identifier
  public_gateway_db_name = var.public_gateway_db_name
  client_gateway_db_name = var.client_gateway_db_name

  vpc       = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc
  app_image = data.terraform_remote_state.core.outputs.services_ecr_repository.repository_url

  db_password_parameter                      = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter
  freeswitch_event_socket_password_parameter = data.aws_ssm_parameter.freeswitch_event_socket_password

  db_security_group            = data.terraform_remote_state.core_infrastructure.outputs.db_security_group
  db_username                  = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_host                      = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port                      = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  sip_port                     = var.sip_port
  sip_alternative_port         = var.sip_alternative_port
  freeswitch_event_socket_port = var.freeswitch_event_socket_port
  media_proxy_ng_port          = module.media_proxy.ng_port
}
