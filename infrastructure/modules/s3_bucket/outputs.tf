output "this" {
  value = aws_s3_bucket.this
}

output "access_key_id_parameter" {
  value = aws_ssm_parameter.access_key_id
}

output "secret_access_key_parameter" {
  value = aws_ssm_parameter.secret_access_key
}
