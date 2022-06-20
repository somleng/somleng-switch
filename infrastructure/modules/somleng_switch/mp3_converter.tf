locals {
  mp3_converter_function_name = "${var.app_identifier}_mp3_converter"
}

resource "aws_iam_role" "mp3_converter" {
  name = local.mp3_converter_function_name

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

resource "aws_lambda_function" "mp3_converter" {
  function_name = local.mp3_converter_function_name

  depends_on = [
    aws_iam_role_policy_attachment.mp3_converter,
    aws_cloudwatch_log_group.mp3_converter
  ]
}

resource "aws_cloudwatch_log_group" "mp3_converter" {
  name              = "/aws/lambda/${local.mp3_converter_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "mp3_converter" {
  name = local.mp3_converter_function_name

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
        "${aws_s3_bucket.recordings.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "mp3_converter_lambda_basic_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "mp3_converter" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.mp3_converter.arn
}

resource "aws_lambda_permission" "mp3_converter" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mp3_converter.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.recordings.arn
}

resource "aws_s3_bucket_notification" "mp3_converter" {
  bucket = aws_s3_bucket.recordings.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.mp3_converter.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".wav"
  }

  depends_on = [aws_lambda_permission.mp3_converter]
}
