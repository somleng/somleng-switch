resource "aws_s3_bucket" "recordings" {
  bucket = var.recordings_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    id     = "rule-1"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_iam_user" "recordings" {
  name = "${var.identifier}_recordings"
}

resource "aws_iam_access_key" "recordings" {
  user = aws_iam_user.recordings.name
}

resource "aws_iam_user_policy" "recordings" {
  name = aws_iam_user.recordings.name
  user = aws_iam_user.recordings.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.recordings.arn}/*"
    }
  ]
}
EOF
}
