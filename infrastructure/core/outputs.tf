output "public_gateway_ecr_repository" {
  value = aws_ecrpublic_repository.public_gateway
}

output "client_gateway_ecr_repository" {
  value = aws_ecrpublic_repository.client_gateway
}

output "media_proxy_ecr_repository" {
  value = aws_ecrpublic_repository.media_proxy
}

output "opensips_scheduler_ecr_repository" {
  value = aws_ecrpublic_repository.opensips_scheduler
}

output "app_ecr_repository" {
  value = module.app_ecr_repository
}

output "webserver_ecr_repository" {
  value = module.webserver_ecr_repository
}

output "freeswitch_ecr_repository" {
  value = module.freeswitch_ecr_repository
}

output "freeswitch_event_logger_ecr_repository" {
  value = module.freeswitch_event_logger_ecr_repository
}

output "s3_mpeg_ecr_repository" {
  value = module.s3_mpeg_ecr_repository
}

output "services_ecr_repository" {
  value = module.services_ecr_repository
}
