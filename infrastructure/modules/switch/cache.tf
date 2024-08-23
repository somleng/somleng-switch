locals {
  cache_file_system = var.cache_file_system != null ? var.cache_file_system : module.cache.file_system
}

module "cache" {
  source              = "../efs"
  vpc                 = var.vpc
  name                = var.cache_name
  security_group_name = var.cache_security_group_name
  file_system         = var.cache_file_system
}
