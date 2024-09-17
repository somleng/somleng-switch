module "switch" {
  source = "../modules/switch"

  json_cdr_url                                       = "https://api-staging.somleng.org/services/call_data_records"
  target_group_name                                  = "switch-staging-internal"
  cache_name                                         = "switch-staging-cache"
  cache_security_group_name                          = "switch-staging-efs-cache"
  recordings_bucket_name                             = "raw-recordings-staging.somleng.org"
  application_master_key_parameter_name              = "somleng-switch.${var.app_environment}.application_master_key"
  rayo_password_parameter_name                       = "somleng-switch.${var.app_environment}.rayo_password"
  freeswitch_event_socket_password_parameter_name    = "somleng-switch.${var.app_environment}.freeswitch_event_socket_password"
  recordings_bucket_access_key_id_parameter_name     = "somleng-switch.${var.app_environment}.recordings_bucket_access_key_id"
  recordings_bucket_secret_access_key_parameter_name = "somleng-switch.${var.app_environment}.recordings_bucket_secret_access_key"
  min_tasks                                          = 0
  max_tasks                                          = 2
  lb_rule_index                                      = 120
  identifier                                         = var.switch_identifier
  app_environment                                    = var.app_environment
  region                                             = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region
  ecs_cluster                                        = aws_ecs_cluster.this
  sip_port                                           = var.sip_port
  sip_alternative_port                               = var.sip_alternative_port
  freeswitch_event_socket_port                       = var.freeswitch_event_socket_port
  json_cdr_password_parameter                        = data.aws_ssm_parameter.somleng_services_password
  services_function                                  = module.services
  internal_route53_zone                              = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
  app_image                                          = data.terraform_remote_state.core.outputs.app_ecr_repository.this.repository_url
  nginx_image                                        = data.terraform_remote_state.core.outputs.webserver_ecr_repository.this.repository_url
  freeswitch_image                                   = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.this.repository_url
  freeswitch_event_logger_image                      = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.this.repository_url
  external_rtp_ip                                    = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc.nat_public_ips[0]
  alternative_sip_outbound_ip                        = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.nat_instance.public_ip
  alternative_rtp_ip                                 = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.nat_instance.public_ip
}

module "switch_helium" {
  source = "../modules/switch"

  region                                        = data.terraform_remote_state.core_infrastructure.outputs.helium_region
  ecs_cluster                                   = aws_ecs_cluster.helium
  external_rtp_ip                               = data.terraform_remote_state.core_infrastructure.outputs.helium_region.vpc.nat_public_ips[0]
  alternative_sip_outbound_ip                   = data.terraform_remote_state.core_infrastructure.outputs.helium_region.vpc.nat_public_ips[0]
  alternative_rtp_ip                            = data.terraform_remote_state.core_infrastructure.outputs.helium_region.vpc.nat_public_ips[0]
  identifier                                    = module.switch.identifier
  lb_rule_index                                 = module.switch.lb_rule_index
  app_environment                               = module.switch.app_environment
  json_cdr_url                                  = module.switch.json_cdr_url
  cache_name                                    = module.switch.cache_name
  recordings_bucket                             = module.switch.recordings_bucket
  recordings_bucket_access_key_id_parameter     = module.switch.recordings_bucket_access_key_id_parameter
  recordings_bucket_secret_access_key_parameter = module.switch.recordings_bucket_secret_access_key_parameter
  application_master_key_parameter              = module.switch.application_master_key_parameter
  rayo_password_parameter                       = module.switch.rayo_password_parameter
  freeswitch_event_socket_password_parameter    = module.switch.freeswitch_event_socket_password_parameter
  container_instance_profile                    = module.switch.container_instances.iam_instance_profile
  iam_task_role                                 = module.switch.iam_task_role
  iam_task_execution_role                       = module.switch.iam_task_execution_role
  min_tasks                                     = module.switch.min_tasks
  max_tasks                                     = module.switch.max_tasks
  sip_port                                      = module.switch.sip_port
  sip_alternative_port                          = module.switch.sip_alternative_port
  freeswitch_event_socket_port                  = module.switch.freeswitch_event_socket_port
  json_cdr_password_parameter                   = module.switch.json_cdr_password_parameter
  services_function                             = module.switch.services_function
  app_image                                     = module.switch.app_image
  nginx_image                                   = module.switch.nginx_image
  freeswitch_image                              = module.switch.freeswitch_image
  freeswitch_event_logger_image                 = module.switch.freeswitch_event_logger_image
  internal_route53_zone                         = module.switch.internal_route53_zone
  target_event_bus                              = module.switch.target_event_bus

  providers = {
    aws = aws.helium
  }
}
