resource "aws_elasticache_replication_group" "this" {
  automatic_failover_enabled = var.automatic_failover_enabled
  description                = "Replication group for ${var.identifier}"
  replication_group_id       = var.identifier
  engine                     = var.engine
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_clusters
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  snapshot_retention_limit   = 30

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = var.vpc.database_subnets
}
