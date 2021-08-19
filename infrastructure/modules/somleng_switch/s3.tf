resource "aws_s3_bucket" "tts_cache" {
  bucket = "tts-cache.somleng.org"
  acl    = "private"
}
