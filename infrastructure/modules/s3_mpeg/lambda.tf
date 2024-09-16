resource "aws_lambda_function" "this" {
  function_name = var.identifier
  role          = aws_iam_role.this.arn
  package_type  = "Image"
  architectures = ["arm64"]
  image_uri     = docker_registry_image.this.name
  timeout       = 300
  memory_size   = 1024

  environment {
    variables = {
      APP_MASTER_KEY_SSM_PARAMETER_NAME = aws_ssm_parameter.application_master_key.name
      APP_ENV                           = var.app_environment
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.this,
    aws_cloudwatch_log_group.this
  ]

  lifecycle {
    ignore_changes = [
      image_uri
    ]
  }
}

resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.recordings_bucket.arn
}
