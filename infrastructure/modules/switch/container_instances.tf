module "container_instances" {
  source = "../container_instances"

  app_identifier   = var.identifier
  vpc              = var.vpc
  instance_subnets = var.vpc.private_subnets
  cluster_name     = var.ecs_cluster.name
  max_capacity     = var.max_tasks * 2
}
