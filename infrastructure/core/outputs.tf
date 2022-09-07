output "switch_ecr_repository" {
  value = aws_ecrpublic_repository.switch
}

output "nginx_ecr_repository" {
  value = aws_ecrpublic_repository.nginx
}

output "freeswitch_ecr_repository" {
  value = aws_ecrpublic_repository.freeswitch
}

output "freeswitch_event_logger_ecr_repository" {
  value = aws_ecrpublic_repository.freeswitch_event_logger
}

output "opensips_ecr_repository" {
  value = aws_ecrpublic_repository.opensips
}

output "client_gateway_ecr_repository" {
  value = aws_ecrpublic_repository.client_gateway
}

output "opensips_scheduler_ecr_repository" {
  value = aws_ecrpublic_repository.opensips_scheduler
}

output "s3_mpeg_ecr_repository" {
  value = aws_ecr_repository.s3_mpeg
}

output "services_ecr_repository" {
  value = aws_ecr_repository.services
}
