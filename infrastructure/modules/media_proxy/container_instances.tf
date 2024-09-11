module "container_instances" {
  source = "../container_instances"

  app_identifier              = var.identifier
  vpc                         = var.vpc
  instance_subnets            = var.vpc.public_subnets
  associate_public_ip_address = true
  cluster_name                = var.ecs_cluster.name
  max_capacity                = var.max_tasks * 2
  architecture                = "arm64"
  instance_type               = "t4g.small"
  user_data = var.assign_eips ? [
    {
      path = "/opt/assign_eip.sh",
      content = templatefile(
        "${path.module}/templates/assign_eip.sh",
        {
          eip_tag = var.identifier
        }
      ),
      permissions = "755"
    }
  ] : []
}
