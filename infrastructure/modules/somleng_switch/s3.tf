resource "aws_s3_bucket" "tts_cache" {
  bucket = var.tts_cache_bucket_name
  acl    = "private"
}

resource "aws_s3_bucket" "recording" {
  bucket = var.recording_bucket_name
  acl    = "private"
}
