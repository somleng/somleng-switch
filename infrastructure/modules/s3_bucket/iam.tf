resource "aws_iam_user" "this" {
  name = var.iam_username

}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_iam_user_policy" "this" {
  name = aws_iam_user.this.name
  user = aws_iam_user.this.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.this.arn}/*"
    }
  ]
}
EOF
}
