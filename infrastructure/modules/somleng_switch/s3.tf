resource "aws_s3_bucket" "tts_cache" {
  bucket = var.tts_cache_bucket_name
  acl    = "private"
}
