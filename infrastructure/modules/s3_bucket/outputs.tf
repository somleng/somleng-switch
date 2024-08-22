output "this" {
  value = aws_s3_bucket.this
}

output "access_key_id" {
  value = aws_iam_access_key.this.id
}

output "secret_access_key" {
  value = aws_iam_access_key.this.secret
}
