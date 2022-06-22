terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    local = {
      source = "hashicorp/local"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
  required_version = ">= 0.13"
}
