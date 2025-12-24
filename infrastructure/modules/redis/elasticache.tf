resource "aws_elasticache_serverless_cache" "this" {
  engine                   = var.engine
  name                     = var.identifier
  security_group_ids       = [aws_security_group.this.id]
  subnet_ids               = var.vpc.database_subnets
  snapshot_retention_limit = 30
}
