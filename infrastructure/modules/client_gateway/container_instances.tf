module "container_instances" {
  source = "../container_instances"

  app_identifier              = var.identifier
  vpc                         = var.vpc
  instance_subnets            = var.vpc.public_subnets
  associate_public_ip_address = true
  max_capacity                = var.max_tasks * 2
  cluster_name                = var.ecs_cluster.name
  security_groups             = [var.db_security_group.id]
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
