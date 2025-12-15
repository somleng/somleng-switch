module "rating_engine" {
  source = "../modules/rating_engine"

  identifier      = var.rating_engine_identifier
  app_environment = var.app_environment

  http_password_parameter_name   = "somleng-rating-engine.${var.app_environment}.http_password"
  stordb_password_parameter_name = "somleng-rating-engine.${var.app_environment}.stordb_password"

  # stordb_dbname = var.stordb_dbname
  # stordb_host   = var.stordb_host
  # stordb_port   = var.stordb_port
  # stordb_user   = var.stordb_user

  # datadb_host   = var.datadb_host
  # datadb_port   = var.datadb_port
  # datadb_dbname = var.datadb_dbname
  # datadb_user   = var.datadb_user
}
