module container_instances {
  source = "../container_instances"

  app_identifier = var.app_identifier
  vpc_id = var.vpc_id
  instance_subnets = var.container_instance_subnets
  cluster_name = local.cluster_name
}
