data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  registry_auth {
    address  = split("/", var.app_image)[0]
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

resource "docker_image" "this" {
  name = "${var.app_image}:latest"
  build {
    context = abspath("${path.module}/../../../components/s3_mpeg")
  }
}

resource "docker_registry_image" "this" {
  name          = docker_image.this.name
  keep_remotely = true
}
