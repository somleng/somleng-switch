module "public_gateway_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "public-gateway"
}

module "client_gateway_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "client-gateway"
}

module "media_proxy_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "media-proxy"
}

module "gateway_scheduler_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "gateway-scheduler"
}

module "app_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "switch-app"
}

module "webserver_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "switch-webserver"
}

module "freeswitch_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "freeswitch"
}

module "freeswitch_event_logger_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "freeswitch-events"
}

module "s3_mpeg_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "s3-mpeg"
}

module "services_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "switch-services"
}
