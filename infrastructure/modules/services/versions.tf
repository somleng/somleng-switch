terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    local = {
      source = "hashicorp/local"
    }
    tls = {
      source = "hashicorp/tls"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 0.13"
}
