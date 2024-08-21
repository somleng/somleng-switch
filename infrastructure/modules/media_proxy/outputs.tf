output "capacity_provider" {
  value = aws_ecs_capacity_provider.media_proxy
}

output "ng_port" {
  value = var.ng_port
}
