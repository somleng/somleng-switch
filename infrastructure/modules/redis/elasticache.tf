resource "aws_elasticache_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = var.vpc.database_subnets
}

resource "aws_elasticache_replication_group" "this" {
  automatic_failover_enabled = var.automatic_failover_enabled
  description                = var.identifier
  replication_group_id       = var.identifier
  engine                     = var.engine
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_clusters
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  snapshot_retention_limit   = 30
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = var.transit_encryption_mode
  apply_immediately          = true

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.this.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.this.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}
