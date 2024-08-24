module "cache" {
  source              = "../efs"
  vpc                 = var.vpc
  name                = var.cache_name
  security_group_name = var.cache_security_group_name
}
