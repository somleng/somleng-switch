output "capacity_provider" {
  value = aws_ecs_capacity_provider.this
}

output "recordings_bucket" {
  value = local.recordings_bucket
}
