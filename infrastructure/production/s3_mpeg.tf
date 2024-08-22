module "s3_mpeg" {
  source = "../modules/s3_mpeg"

  identifier        = var.s3_mpeg_identifier
  app_image         = data.terraform_remote_state.core.outputs.s3_mpeg_ecr_repository.repository_url
  recordings_bucket = module.switch.recordings_bucket.this
}
