variable "aws_region" {
  default = "ap-southeast-1"
}

variable "app_environment" {
  default = "staging"
}

variable "switch_identifier" {
  default = "switch-staging"
}

variable "services_identifier" {
  default = "switch-services-staging"
}

variable "s3_mpeg_identifier" {
  default = "s3-mpeg-staging"
}

variable "public_gateway_identifier" {
  default = "public-gateway-staging"
}

variable "client_gateway_identifier" {
  default = "client-gateway-staging"
}

variable "media_proxy_identifier" {
  default = "media-proxy-staging"
}

variable "client_gateway_db_name" {
  default = "opensips_client_gateway_staging"
}

variable "public_gateway_db_name" {
  default = "opensips_public_gateway_staging"
}

variable "sip_port" {
  default = 6060
}

variable "sip_alternative_port" {
  default = 6080
}

variable "freeswitch_event_socket_port" {
  default = 8021
}

variable "media_proxy_ng_port" {
  default = 2223
}
