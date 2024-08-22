output "capacity_provider" {
  value = aws_ecs_capacity_provider.this
}

output "recordings_bucket" {
  value = module.recordings_bucket
}
