resource "aws_s3_bucket_notification" "this" {
  bucket = var.recordings_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".wav"
  }

  depends_on = [aws_lambda_permission.this]
}
