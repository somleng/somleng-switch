output "app_ecr_repository" {
  value = aws_ecrpublic_repository.app
}

output "nginx_ecr_repository" {
  value = aws_ecrpublic_repository.nginx
}

output "freeswitch_ecr_repository" {
  value = aws_ecrpublic_repository.freeswitch
}

output "s3_mpeg_ecr_repository" {
  value = aws_ecr_repository.s3_mpeg
}
