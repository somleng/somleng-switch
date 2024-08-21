output "public_gateway_capacity_provider" {
  value = aws_ecs_capacity_provider.public_gateway
}

output "media_proxy_capacity_provider" {
  value = aws_ecs_capacity_provider.media_proxy
}
