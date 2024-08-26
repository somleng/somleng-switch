module "switch" {
  source = "../modules/switch"

  json_cdr_url                                       = "https://api.internal.somleng.org/services/call_data_records"
  target_group_name                                  = "switch-internal"
  cache_name                                         = "somleng-switch-cache"
  cache_security_group_name                          = "switch-efs-cache"
  recordings_bucket_name                             = "raw-recordings.somleng.org"
  application_master_key_parameter_name              = "somleng-switch.${var.app_environment}.application_master_key"
  rayo_password_parameter_name                       = "somleng-switch.${var.app_environment}.rayo_password"
  freeswitch_event_socket_password_parameter_name    = "somleng-switch.${var.app_environment}.freeswitch_event_socket_password"
  recordings_bucket_access_key_id_parameter_name     = "somleng-switch.${var.app_environment}.recordings_bucket_access_key_id"
  recordings_bucket_secret_access_key_parameter_name = "somleng-switch.${var.app_environment}.recordings_bucket_secret_access_key"
  max_tasks                                          = 10
  identifier                                         = var.switch_identifier
  app_environment                                    = var.app_environment
  region                                             = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region
  ecs_cluster                                        = aws_ecs_cluster.this
  sip_port                                           = var.sip_port
  sip_alternative_port                               = var.sip_alternative_port
  freeswitch_event_socket_port                       = var.freeswitch_event_socket_port
  json_cdr_password_parameter                        = data.aws_ssm_parameter.somleng_services_password
  services_function                                  = module.services.function
  internal_route53_zone                              = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org
  lb_rule_index                                      = 20
  app_image                                          = data.terraform_remote_state.core.outputs.switch_ecr_repository.repository_uri
  nginx_image                                        = data.terraform_remote_state.core.outputs.nginx_ecr_repository.repository_uri
  freeswitch_image                                   = data.terraform_remote_state.core.outputs.freeswitch_ecr_repository.repository_uri
  freeswitch_event_logger_image                      = data.terraform_remote_state.core.outputs.freeswitch_event_logger_ecr_repository.repository_uri
  external_rtp_ip                                    = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc.nat_public_ips[0]
  alternative_sip_outbound_ip                        = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
  alternative_rtp_ip                                 = data.terraform_remote_state.core_infrastructure.outputs.nat_instance_ip
}


resource "aws_route53_record" "switch_legacy" {
  zone_id = data.terraform_remote_state.core_infrastructure.outputs.route53_zone_internal_somleng_org_old.zone_id
  name    = "switch"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.internal_load_balancer.this.dns_name
    zone_id                = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.internal_load_balancer.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener_rule" "switch_legacy" {
  priority     = 30
  listener_arn = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.internal_load_balancer.https_listener.arn

  action {
    type             = "forward"
    target_group_arn = module.switch.target_group.id
  }

  condition {
    host_header {
      values = [aws_route53_record.switch_legacy.fqdn]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}
