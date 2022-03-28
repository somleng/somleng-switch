resource "aws_s3_bucket" "tts_cache" {
  bucket = var.tts_cache_bucket_name
  acl    = "private"
}

resource "aws_s3_bucket" "recordings" {
  bucket = var.recordings_bucket_name
  acl    = "private"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 7
    }
  }
}
