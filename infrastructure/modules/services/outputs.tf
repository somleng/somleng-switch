output "this" {
  value = aws_lambda_function.this
}

output "aws_region" {
  value = data.aws_region.this.name
}
