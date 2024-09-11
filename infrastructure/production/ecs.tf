resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [
    module.switch.capacity_provider.name,
    module.public_gateway.capacity_provider.name,
    module.client_gateway.capacity_provider.name,
    module.media_proxy.capacity_provider.name
  ]
}

resource "aws_ecs_cluster" "helium" {
  name = var.ecs_cluster_name

  provider = aws.helium
}

resource "aws_ecs_cluster_capacity_providers" "helium" {
  cluster_name = aws_ecs_cluster.helium.name

  capacity_providers = [
    module.switch_helium.capacity_provider.name
  ]

  provider = aws.helium
}
