module "media_proxy" {
  source = "../modules/media_proxy"

  identifier      = var.media_proxy_identifier
  app_environment = var.app_environment
  aws_region      = var.aws_default_region

  vpc         = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region.vpc
  ecs_cluster = aws_ecs_cluster.this
  app_image   = data.terraform_remote_state.core.outputs.media_proxy_ecr_repository.this.repository_url
}
