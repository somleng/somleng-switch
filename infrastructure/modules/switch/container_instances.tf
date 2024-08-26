module "container_instances" {
  source = "../container_instances"

  app_identifier       = var.identifier
  vpc                  = var.region.vpc
  instance_subnets     = var.region.vpc.private_subnets
  cluster_name         = var.ecs_cluster.name
  max_capacity         = var.max_tasks * 2
  iam_instance_profile = var.container_instance_profile
}
