output "capacity_provider" {
  value = aws_ecs_capacity_provider.this
}

output "recordings_bucket" {
  value = aws_s3_bucket.recordings
}
