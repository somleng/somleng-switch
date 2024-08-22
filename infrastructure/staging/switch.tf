module "switch" {
  source = "../modules/switch"

  identifier             = var.switch_identifier
  app_environment        = var.app_environment
  json_cdr_url           = "https://api-staging.internal.somleng.org/services/call_data_records"
  subdomain              = "switch-staging"
  efs_cache_name         = "switch-staging-cache"
  recordings_bucket_name = "raw-recordings-staging.somleng.org"

  min_tasks = 0
  max_tasks = 2

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
  aws_region                   = var.aws_region

  app_image                     = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
  nginx_image                   = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image              = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  external_rtp_ip               = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]
  alternative_sip_outbound_ip   = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
  alternative_rtp_ip            = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
}

# module "helium_switch" {
#   source = "../modules/switch"

#   identifier             = var.switch_identifier
#   app_environment        = var.app_environment
#   json_cdr_url           = "https://api-staging.internal.somleng.org/services/call_data_records"
#   subdomain              = "switch-staging"
#   efs_cache_name         = "switch-staging-cache"
#   recordings_bucket_name = "raw-recordings-staging.somleng.org"

#   min_tasks = 0
#   max_tasks = 2

#   vpc                          = data.terraform_remote_state.core_infrastructure.outputs.vpc
#   ecs_cluster                  = aws_ecs_cluster.this
#   sip_port                     = var.sip_port
#   sip_alternative_port         = var.sip_alternative_port
#   freeswitch_event_socket_port = var.freeswitch_event_socket_port
#   json_cdr_password_parameter  = data.aws_ssm_parameter.somleng_services_password
#   services_function            = module.services.function
#   internal_route53_zone        = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
#   internal_load_balancer       = data.terraform_remote_state.core_infrastructure.outputs.internal_application_load_balancer
#   internal_listener            = data.terraform_remote_state.core_infrastructure.outputs.internal_https_listener
#   aws_region                   = var.aws_region

#   app_image                     = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
#   nginx_image                   = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
#   freeswitch_image              = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
#   freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
#   external_rtp_ip               = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]
#   alternative_sip_outbound_ip   = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
#   alternative_rtp_ip            = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
# }
