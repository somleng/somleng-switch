output "app_ecr_repository" {
  value = aws_ecrpublic_repository.app
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

output "s3_mpeg_ecr_repository" {
  value = aws_ecr_repository.s3_mpeg
}
