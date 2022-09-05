data "aws_ssm_parameter" "somleng_services_password" {
  name = "somleng.staging.services_password"
}

module "somleng_switch_staging" {
  source = "../modules/somleng_switch"

  aws_region = var.aws_region
  app_identifier = "somleng-switch-staging"
  registrar_identifier = "somleng-registrar-staging"
  app_environment = "staging"
  switch_image = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
  nginx_image = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  opensips_image = data.terraform_remote_state.core.outputs.opensips_ecr_repository.repository_uri
  opensips_scheduler_image = data.terraform_remote_state.core.outputs.opensips_scheduler_ecr_repository.repository_uri
  registrar_image = data.terraform_remote_state.core.outputs.registrar_ecr_repository.repository_uri

  s3_mpeg_ecr_repository_url = data.terraform_remote_state.core.outputs.s3_mpeg_ecr_repository.repository_url
  services_ecr_repository_url = data.terraform_remote_state.core.outputs.services_ecr_repository.repository_url

  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id
  vpc_cidr_block = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_cidr_block
  container_instance_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.private_subnets
  intra_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.intra_subnets
  public_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.public_subnets

  json_cdr_password_parameter_arn = data.aws_ssm_parameter.somleng_services_password.arn
  json_cdr_url = "https://api-staging.somleng.org/services/call_data_records"
  external_sip_ip = data.terraform_remote_state.core_infrastructure.outputs.nlb_eips[0].public_ip
  external_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]

  alternative_sip_outbound_ip = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
  alternative_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip

  db_name = "opensips_staging"
  db_username = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_password_parameter_arn = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter.arn
  db_host = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  db_security_group = data.terraform_remote_state.core_infrastructure.outputs.db_security_group.id

  load_balancer = data.terraform_remote_state.core_infrastructure.outputs.application_load_balancer
  network_load_balancer = data.terraform_remote_state.core_infrastructure.outputs.network_load_balancer
  route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_somleng_org
  listener_arn = data.terraform_remote_state.core_infrastructure.outputs.https_listener.arn
  inbound_sip_trunks_security_group_name = "somleng-inbound-sip-trunks-staging"
  inbound_sip_trunks_security_group_description = "Somleng Staging Inbound SIP Trunks"
  sip_subdomain = "sip-staging"
  switch_subdomain = "switch-staging"
  registrar_subdomain = "registrar-staging"

  recordings_bucket_name = "raw-recordings-staging.somleng.org"

  sip_port = 6060
  sip_alternative_port = 6080
  switch_min_tasks = 0
  opensips_min_tasks = 0
  registrar_min_tasks = 0
  registrar_max_tasks = 2
}
