data "aws_ssm_parameter" "twilreapi_services_password" {
  name = "twilreapi.production.services_password"
}

module "somleng_switch" {
  source = "../modules/somleng_switch"

  ecs_cluster = data.terraform_remote_state.core_infrastructure.outputs.ecs_cluster
  codedeploy_role = data.terraform_remote_state.core_infrastructure.outputs.codedeploy_role
  app_identifier = "somleng-switch"
  app_environment = "production"
  app_image = data.terraform_remote_state.core.outputs.app_ecr_repository
  nginx_image = data.terraform_remote_state.core.outputs.nginx_ecr_repository
  freeswitch_image = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository
  memory = 2048
  cpu = 1024
  aws_region = var.aws_region
  container_instance_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.private_subnets
  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id

  db_username = data.terraform_remote_state.core_infrastructure.outputs.db.this_rds_cluster_master_username
  db_password_parameter_arn = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter.arn
  db_host = data.terraform_remote_state.core_infrastructure.outputs.db.this_rds_cluster_endpoint
  db_port = data.terraform_remote_state.core_infrastructure.outputs.db.this_rds_cluster_port
  db_security_group = data.terraform_remote_state.core_infrastructure.outputs.db_security_group.id
  json_cdr_password_parameter_arn = data.aws_ssm_parameter.twilreapi_services_password.arn
  json_cdr_url = "https://twilreapi.somleng.org/services/call_data_records"
  external_sip_ip = data.terraform_remote_state.core_infrastructure.outputs.nlb_eips[0].public_ip
  external_rtp_ip = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]

  load_balancer_arn = data.terraform_remote_state.core_infrastructure.outputs.application_load_balancer.arn
  network_load_balancer_arn = data.terraform_remote_state.core_infrastructure.outputs.network_load_balancer.arn
  listener_arn = data.terraform_remote_state.core_infrastructure.outputs.https_listener.arn
  inbound_sip_trunks_security_group_name = "twilreapi-inbound-sip-trunks"

  ecs_appserver_autoscale_min_instances = 1

  webserver_container_port = 8080
  sip_port = 5061
}
