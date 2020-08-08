module "somleng_adhearsion" {
  source = "../modules/somleng_adhearsion"

  ecs_cluster = data.terraform_remote_state.core_infrastructure.outputs.ecs_cluster
  app_identifier = "somleng-adhearsion"
  app_environment = "production"
  app_image = data.terraform_remote_state.core.outputs.app_ecr_repository
  memory = 512
  cpu = 256
  aws_region = var.aws_region
  container_instance_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.private_subnets
  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id
  ecs_worker_autoscale_min_instances = 0

  ecs_app_autoscale_min_instances = 0
}
