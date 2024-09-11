variable "aws_default_region" {
  default = "ap-southeast-1"
}

variable "aws_helium_region" {
  default = "us-east-1"
}

variable "app_environment" {
  default = "production"
}

variable "ecs_cluster_name" {
  default = "somleng-switch"
}

variable "switch_identifier" {
  default = "switch"
}

variable "services_identifier" {
  default = "switch-services"
}

variable "s3_mpeg_identifier" {
  default = "s3-mpeg"
}

variable "public_gateway_identifier" {
  default = "public-gateway"
}

variable "client_gateway_identifier" {
  default = "client-gateway"
}

variable "media_proxy_identifier" {
  default = "media-proxy"
}

variable "client_gateway_db_name" {
  default = "opensips_client_gateway"
}

variable "public_gateway_db_name" {
  default = "opensips_public_gateway"
}

variable "sip_port" {
  default = 5060
}

variable "sip_alternative_port" {
  default = 5080
}

variable "freeswitch_event_socket_port" {
  default = 8021
}
