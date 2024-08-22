module "recordings_bucket" {
  source = "../s3_bucket"

  name         = var.recordings_bucket_name
  iam_username = "${var.identifier}_recordings"
}
