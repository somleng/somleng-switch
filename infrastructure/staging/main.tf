data "aws_ssm_parameter" "somleng_services_password" {
  name = "somleng.production.services_password"
}

module "somleng_switch_staging" {
  source = "../modules/somleng_switch"

  app_identifier = "somleng-switch-staging"
  app_environment = "staging"
  app_image = data.terraform_remote_state.core.outputs.app_ecr_repository
  nginx_image = data.terraform_remote_state.core.outputs.nginx_ecr_repository
  freeswitch_image = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository
  aws_region = var.aws_region
  container_instance_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.private_subnets
  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id

  db_name = "freeswitch_staging"
  db_username = data.terraform_remote_state.core_infrastructure.outputs.db.rds_cluster_master_username
  db_password_parameter_arn = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter.arn
  db_host = data.terraform_remote_state.core_infrastructure.outputs.db.rds_cluster_endpoint
  db_port = data.terraform_remote_state.core_infrastructure.outputs.db.rds_cluster_port
  db_security_group = data.terraform_remote_state.core_infrastructure.outputs.db_security_group.id
  json_cdr_password_parameter_arn = data.aws_ssm_parameter.somleng_services_password.arn
  json_cdr_url = "https://api.somleng.org/services/call_data_records"
  external_sip_ip = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]
  external_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]

  load_balancer = data.terraform_remote_state.core_infrastructure.outputs.application_load_balancer
  network_load_balancer = data.terraform_remote_state.core_infrastructure.outputs.network_load_balancer
  route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_somleng_org
  listener_arn = data.terraform_remote_state.core_infrastructure.outputs.https_listener.arn
  inbound_sip_trunks_security_group_name = "somleng-inbound-sip-trunks-staging"
  inbound_sip_trunks_security_group_description = "Somleng Staging Inbound SIP Trunks"
  sip_subdomain = "sip-staging"
  switch_subdomain = "switch-staging"
  tts_cache_bucket_name = "tts-cache-staging.somleng.org"
  sip_port = 6060
  listener_rule_priority = 120
}
