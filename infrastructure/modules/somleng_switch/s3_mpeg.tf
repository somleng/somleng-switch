module "s3_mpeg" {
  source = "/Users/dwilkie/work/somleng/s3-mpeg"

  function_name = "${var.app_identifier}_s3_mpeg"
  filter_suffix = ".wav"
  bucket_name = aws_s3_bucket.recordings.id
}
