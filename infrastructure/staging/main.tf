data "aws_ssm_parameter" "somleng_services_password" {
  name = "somleng.staging.services_password"
}

module "somleng_switch_staging" {
  source = "../modules/somleng_switch"

  aws_region = var.aws_region
  app_identifier = "somleng-switch-staging"
  app_environment = "staging"
  app_image = data.terraform_remote_state.core.outputs.app_ecr_repository.repository_uri
  nginx_image = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  s3_mpeg_ecr_repository_url = data.terraform_remote_state.core.outputs.s3_mpeg_ecr_repository.repository_url

  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id
  container_instance_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.private_subnets
  intra_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.intra_subnets

  db_name = "freeswitch_staging"
  db_username = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_password_parameter_arn = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter.arn
  db_host = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  db_security_group = data.terraform_remote_state.core_infrastructure.outputs.db_security_group.id

  json_cdr_password_parameter_arn = data.aws_ssm_parameter.somleng_services_password.arn
  json_cdr_url = "https://api-staging.somleng.org/services/call_data_records"
  external_sip_ip = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]
  external_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]
  external_nat_instance_sip_ip = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
  external_nat_instance_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip

  load_balancer = data.terraform_remote_state.core_infrastructure.outputs.application_load_balancer
  network_load_balancer = data.terraform_remote_state.core_infrastructure.outputs.network_load_balancer
  route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_somleng_org
  listener_arn = data.terraform_remote_state.core_infrastructure.outputs.https_listener.arn
  inbound_sip_trunks_security_group_name = "somleng-inbound-sip-trunks-staging"
  inbound_sip_trunks_security_group_description = "Somleng Staging Inbound SIP Trunks"
  sip_subdomain = "sip-staging"
  switch_subdomain = "switch-staging"
  recordings_bucket_name = "raw-recordings-staging.somleng.org"
  load_balancer_sip_port = 6060
  listener_rule_priority = 120
  min_tasks = 1
  container_insights_enabled = true
}
