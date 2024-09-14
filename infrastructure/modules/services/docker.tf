resource "docker_image" "this" {
  name = "${var.app_image}:latest"
  build {
    context = abspath("${path.module}/../../../components/services")
  }
}

resource "docker_registry_image" "this" {
  name          = docker_image.this.name
  keep_remotely = true
}
