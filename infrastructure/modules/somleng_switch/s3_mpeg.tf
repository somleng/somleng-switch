locals {
  s3_mpeg_function_name = "${var.s3_mpeg_identifier}"
  s3_filter_suffix = ".wav"
}

resource "docker_registry_image" "s3_mpeg" {
  name = "${var.s3_mpeg_ecr_repository_url}:latest"

  build {
    context = abspath("${path.module}/../../../components/s3_mpeg")
  }

  lifecycle {
    ignore_changes = [
      build[0].context
    ]
  }
}

resource "aws_iam_role" "s3_mpeg" {
  name = local.s3_mpeg_function_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "s3_mpeg" {
  function_name = local.s3_mpeg_function_name
  role = aws_iam_role.s3_mpeg.arn
  package_type = "Image"
  architectures = ["arm64"]
  image_uri = docker_registry_image.s3_mpeg.name
  timeout = 300
  memory_size = 1024

  depends_on = [
    aws_iam_role_policy_attachment.s3_mpeg,
    aws_cloudwatch_log_group.s3_mpeg
  ]

  lifecycle {
    ignore_changes = [
      image_uri
    ]
  }
}

resource "aws_cloudwatch_log_group" "s3_mpeg" {
  name              = "/aws/lambda/${local.s3_mpeg_function_name}"
  retention_in_days = 7
}

resource "aws_iam_policy" "s3_mpeg" {
  name = local.s3_mpeg_function_name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.recordings.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_mpeg_aws_lambda_basic_execution_role" {
  role       = aws_iam_role.s3_mpeg.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_mpeg" {
  role       = aws_iam_role.s3_mpeg.name
  policy_arn = aws_iam_policy.s3_mpeg.arn
}

resource "aws_lambda_permission" "s3_mpeg" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_mpeg.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.recordings.arn
}

resource "aws_s3_bucket_notification" "s3_mpeg" {
  bucket = aws_s3_bucket.recordings.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_mpeg.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = local.s3_filter_suffix
  }

  depends_on = [aws_lambda_permission.s3_mpeg]
}
