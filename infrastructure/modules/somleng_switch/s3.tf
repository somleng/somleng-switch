resource "aws_s3_bucket" "tts_cache" {
  bucket = var.tts_cache_bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tts_cache" {
  bucket = aws_s3_bucket.tts_cache.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "recordings" {
  bucket = var.recordings_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    id = "rule-1"
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
      sse_algorithm     = "aws:kms"
    }
  }
}
