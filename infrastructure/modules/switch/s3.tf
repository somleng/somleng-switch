locals {
  create_recordings_bucket = var.recordings_bucket == null && var.recordings_bucket_name != null
  recordings_bucket        = var.recordings_bucket != null ? var.recordings_bucket : module.recordings_bucket[0].this
}

module "recordings_bucket" {
  source = "../s3_bucket"
  count  = local.create_recordings_bucket ? 1 : 0

  name         = var.recordings_bucket_name
  iam_username = "${var.identifier}_recordings"
}
