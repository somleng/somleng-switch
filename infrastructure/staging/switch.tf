module "switch" {
  source = "../modules/switch"

  identifier                                         = var.switch_identifier
  app_environment                                    = var.app_environment
  json_cdr_url                                       = "https://api-staging.internal.somleng.org/services/call_data_records"
  subdomain                                          = "switch-staging"
  cache_name                                         = "switch-staging-cache"
  cache_security_group_name                          = "switch-staging-efs-cache"
  recordings_bucket_name                             = "raw-recordings-staging.somleng.org"
  application_master_key_parameter_name              = "somleng-switch.${var.app_environment}.application_master_key"
  rayo_password_parameter_name                       = "somleng-switch.${var.app_environment}.rayo_password"
  freeswitch_event_socket_password_parameter_name    = "somleng-switch.${var.app_environment}.freeswitch_event_socket_password"
  recordings_bucket_access_key_id_parameter_name     = "somleng-switch.${var.app_environment}.recordings_bucket_access_key_id"
  recordings_bucket_secret_access_key_parameter_name = "somleng-switch.${var.app_environment}.recordings_bucket_secret_access_key"

  min_tasks = 0
  max_tasks = 2

  aws_region                   = var.aws_default_region
  vpc                          = data.terraform_remote_state.core_infrastructure.outputs.vpc
  ecs_cluster                  = aws_ecs_cluster.this
  sip_port                     = var.sip_port
  sip_alternative_port         = var.sip_alternative_port
  freeswitch_event_socket_port = var.freeswitch_event_socket_port
  json_cdr_password_parameter  = data.aws_ssm_parameter.somleng_services_password
  services_function            = module.services.function
  internal_route53_zone        = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
  internal_load_balancer       = data.terraform_remote_state.core_infrastructure.outputs.internal_application_load_balancer
  internal_listener            = data.terraform_remote_state.core_infrastructure.outputs.internal_https_listener

  app_image                     = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
  nginx_image                   = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image              = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  external_rtp_ip               = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]
  alternative_sip_outbound_ip   = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
  alternative_rtp_ip            = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
}

module "switch_helium" {
  source = "../modules/switch"

  identifier                                    = var.switch_identifier
  app_environment                               = var.app_environment
  json_cdr_url                                  = "https://api-staging.internal.somleng.org/services/call_data_records"
  subdomain                                     = "switch-staging"
  recordings_bucket                             = module.switch.recordings_bucket
  recordings_bucket_access_key_id_parameter     = module.switch.recordings_bucket_access_key_id_parameter
  recordings_bucket_secret_access_key_parameter = module.switch.recordings_bucket_secret_access_key_parameter
  application_master_key_parameter              = module.switch.application_master_key_parameter
  rayo_password_parameter                       = module.switch.rayo_password_parameter
  freeswitch_event_socket_password_parameter    = module.switch.freeswitch_event_socket_password_parameter
  container_instance_profile                    = module.switch.container_instances.iam_instance_profile
  iam_task_role                                 = module.switch.iam_task_role
  iam_task_execution_role                       = module.switch.iam_task_execution_role
  cache_file_system                             = module.switch.cache_file_system

  min_tasks = 0
  max_tasks = 2

  aws_region                   = var.aws_helium_region
  vpc                          = data.terraform_remote_state.core_infrastructure.outputs.vpc_helium
  ecs_cluster                  = aws_ecs_cluster.helium
  sip_port                     = var.sip_port
  sip_alternative_port         = var.sip_alternative_port
  freeswitch_event_socket_port = var.freeswitch_event_socket_port
  json_cdr_password_parameter  = data.aws_ssm_parameter.somleng_services_password
  services_function            = module.services.function
  internal_route53_zone        = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
  internal_load_balancer       = data.terraform_remote_state.core_infrastructure.outputs.internal_application_load_balancer
  internal_listener            = data.terraform_remote_state.core_infrastructure.outputs.internal_https_listener

  app_image                     = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
  nginx_image                   = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image              = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  external_rtp_ip               = data.terraform_remote_state.core_infrastructure.outputs.vpc_helium.nat_public_ips[0]
  alternative_sip_outbound_ip   = data.terraform_remote_state.core_infrastructure.outputs.vpc_helium.nat_public_ips[0]
  alternative_rtp_ip            = data.terraform_remote_state.core_infrastructure.outputs.vpc_helium.nat_public_ips[0]

  providers = {
    aws = aws.helium
  }
}
