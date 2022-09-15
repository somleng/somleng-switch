data "aws_ssm_parameter" "somleng_services_password" {
  name = "somleng.production.services_password"
}

module "somleng_switch" {
  source = "../modules/somleng_switch"

  app_identifier = "somleng-switch"
  app_environment = "production"
  aws_region = var.aws_region

  switch_image = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
  nginx_image = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  opensips_image = data.terraform_remote_state.core.outputs.opensips_ecr_repository.repository_uri
  opensips_scheduler_image = data.terraform_remote_state.core.outputs.opensips_scheduler_ecr_repository.repository_uri

  s3_mpeg_ecr_repository_url = data.terraform_remote_state.core.outputs.s3_mpeg_ecr_repository.repository_url
  services_ecr_repository_url = data.terraform_remote_state.core.outputs.services_ecr_repository.repository_url

  vpc = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc
  public_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.public_subnets

  json_cdr_password_parameter_arn = data.aws_ssm_parameter.somleng_services_password.arn
  json_cdr_url = "https://api.somleng.org/services/call_data_records"
  external_sip_ip = data.terraform_remote_state.core_infrastructure.outputs.nlb_eips[0].public_ip
  external_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]

  alternative_sip_outbound_ip = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
  alternative_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip

  db_name = "opensips"
  db_username = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_password_parameter_arn = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter.arn
  db_host = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  db_security_group = data.terraform_remote_state.core_infrastructure.outputs.db_security_group.id

  load_balancer = data.terraform_remote_state.core_infrastructure.outputs.application_load_balancer
  network_load_balancer = data.terraform_remote_state.core_infrastructure.outputs.network_load_balancer
  route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_somleng_org
  listener_arn = data.terraform_remote_state.core_infrastructure.outputs.https_listener.arn
  inbound_sip_trunks_security_group_name = "somleng-inbound-sip-trunks"
  sip_subdomain = "sip"
  switch_subdomain = "ahn"
  client_gateway_subdomain = "client_gateway"

  recordings_bucket_name = "raw-recordings.somleng.org"
  switch_max_tasks = 10
}
