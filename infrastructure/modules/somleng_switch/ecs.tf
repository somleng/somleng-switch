resource "aws_ecs_cluster" "cluster" {
  name = var.app_identifier

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = [
    aws_ecs_capacity_provider.switch.name,
    aws_ecs_capacity_provider.public_gateway.name,
    aws_ecs_capacity_provider.client_gateway.name
  ]
}
