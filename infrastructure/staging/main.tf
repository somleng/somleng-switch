data "aws_ssm_parameter" "somleng_services_password" {
  name = "somleng.staging.services_password"
}

resource "aws_ecs_cluster" "this" {
  name = "somleng-switch-staging"
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [
    module.switch.capacity_provider.name,
    module.public_gateway.capacity_provider.name,
    module.client_gateway.capacity_provider.name,
    module.media_proxy.capacity_provider.name
  ]
}

resource "aws_ssm_parameter" "freeswitch_event_socket_password" {
  name  = "somleng-switch.staging.freeswitch_event_socket_password"
  type  = "SecureString"
  value = "change-me"

  lifecycle {
    ignore_changes = [value]
  }
}

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

  vpc                                        = data.terraform_remote_state.core_infrastructure.outputs.vpc
  ecs_cluster                                = aws_ecs_cluster.this
  sip_port                                   = var.sip_port
  sip_alternative_port                       = var.sip_alternative_port
  freeswitch_event_socket_port               = var.freeswitch_event_socket_port
  json_cdr_password_parameter                = data.aws_ssm_parameter.somleng_services_password
  freeswitch_event_socket_password_parameter = aws_ssm_parameter.freeswitch_event_socket_password
  services_function                          = module.services.function
  internal_route53_zone                      = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
  internal_load_balancer                     = data.terraform_remote_state.core_infrastructure.outputs.internal_application_load_balancer
  internal_listener                          = data.terraform_remote_state.core_infrastructure.outputs.internal_https_listener
  aws_region                                 = var.aws_region

  app_image                     = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
  nginx_image                   = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image              = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  external_rtp_ip               = data.terraform_remote_state.core_infrastructure.outputs.vpc.nat_public_ips[0]
  alternative_sip_outbound_ip   = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
  alternative_rtp_ip            = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
}

module "services" {
  source = "../modules/services"

  identifier             = var.services_identifier
  app_environment        = var.app_environment
  switch_group           = var.switch_identifier
  media_proxy_group      = var.media_proxy_identifier
  client_gateway_group   = var.client_gateway_identifier
  public_gateway_db_name = var.public_gateway_db_name
  client_gateway_db_name = var.client_gateway_db_name

  vpc       = data.terraform_remote_state.core_infrastructure.outputs.vpc
  app_image = data.terraform_remote_state.core.outputs.services_ecr_repository.repository_url

  db_password_parameter                      = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter
  freeswitch_event_socket_password_parameter = aws_ssm_parameter.freeswitch_event_socket_password

  db_security_group            = data.terraform_remote_state.core_infrastructure.outputs.db_security_group
  db_username                  = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_host                      = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port                      = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  sip_port                     = var.sip_port
  sip_alternative_port         = var.sip_alternative_port
  freeswitch_event_socket_port = var.freeswitch_event_socket_port
  media_proxy_ng_port          = module.media_proxy.ng_port
  ecs_cluster                  = aws_ecs_cluster.this
}

module "s3_mpeg" {
  source = "../modules/s3_mpeg"

  identifier        = var.s3_mpeg_identifier
  app_image         = data.terraform_remote_state.core.outputs.s3_mpeg_ecr_repository.repository_url
  recordings_bucket = module.switch.recordings_bucket
}

module "public_gateway" {
  source = "../modules/public_gateway"

  identifier      = var.public_gateway_identifier
  app_environment = var.app_environment

  aws_region  = var.aws_region
  vpc         = data.terraform_remote_state.core_infrastructure.outputs.vpc
  ecs_cluster = aws_ecs_cluster.this

  app_image       = data.terraform_remote_state.core.outputs.public_gateway_ecr_repository.repository_uri
  scheduler_image = data.terraform_remote_state.core.outputs.opensips_scheduler_ecr_repository.repository_uri
  min_tasks       = 0
  max_tasks       = 2

  sip_port             = var.sip_port
  sip_alternative_port = var.sip_alternative_port

  db_security_group     = data.terraform_remote_state.core_infrastructure.outputs.db_security_group
  db_password_parameter = data.terraform_remote_state.core_infrastructure.outputs.db_master_password_parameter
  db_name               = var.public_gateway_db_name
  db_username           = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.master_username
  db_host               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.endpoint
  db_port               = data.terraform_remote_state.core_infrastructure.outputs.db_cluster.port
  global_accelerator    = data.terraform_remote_state.core_infrastructure.outputs.global_accelerator
  logs_bucket           = data.terraform_remote_state.core_infrastructure.outputs.logs_bucket
}

module "client_gateway" {
  source = "../modules/client_gateway"

  subdomain = "sip-staging"

  identifier      = var.client_gateway_identifier
  app_environment = var.app_environment

  aws_region   = var.aws_region
  vpc          = data.terraform_remote_state.core_infrastructure.outputs.vpc
  ecs_cluster  = aws_ecs_cluster.this
  route53_zone = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_somleng_org

  app_image       = data.terraform_remote_state.core.outputs.client_gateway_ecr_repository.repository_uri
  scheduler_image = data.terraform_remote_state.core.outputs.opensips_scheduler_ecr_repository.repository_uri
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
  services_function     = module.services.function
}

module "media_proxy" {
  source = "../modules/media_proxy"

  identifier      = var.media_proxy_identifier
  app_environment = var.app_environment
  aws_region      = var.aws_region

  vpc         = data.terraform_remote_state.core_infrastructure.outputs.vpc
  ecs_cluster = aws_ecs_cluster.this
  app_image   = data.terraform_remote_state.core.outputs.media_proxy_ecr_repository.repository_uri

  min_tasks = 0
  max_tasks = 2
}
