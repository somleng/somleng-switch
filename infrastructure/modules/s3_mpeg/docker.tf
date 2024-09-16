data "aws_ecr_authorization_token" "token" {}

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
