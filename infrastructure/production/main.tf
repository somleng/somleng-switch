module "somleng_adhearsion" {
  source = "../modules/somleng_adhearsion"

  ecs_cluster = data.terraform_remote_state.core_infrastructure.outputs.ecs_cluster
  codedeploy_role = data.terraform_remote_state.core_infrastructure.outputs.codedeploy_role
  app_identifier = "somleng-adhearsion"
  app_environment = "production"
  app_image = data.terraform_remote_state.core.outputs.app_ecr_repository
  nginx_image = data.terraform_remote_state.core.outputs.nginx_ecr_repository
  memory = 512
  cpu = 256
  aws_region = var.aws_region
  container_instance_subnets = data.terraform_remote_state.core_infrastructure.outputs.vpc.private_subnets
  vpc_id = data.terraform_remote_state.core_infrastructure.outputs.vpc.vpc_id

  load_balancer_arn = data.terraform_remote_state.core_infrastructure.outputs.application_load_balancer.arn
  listener_arn = data.terraform_remote_state.core_infrastructure.outputs.https_listener.arn

  ecs_appserver_autoscale_min_instances = 1

  ahn_core_host = "freeswitch.somleng.org"
}
