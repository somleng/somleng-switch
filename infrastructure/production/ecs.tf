resource "aws_ecs_cluster" "this" {
  name = "somleng-switch"
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
