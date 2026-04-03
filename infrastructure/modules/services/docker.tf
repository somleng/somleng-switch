resource "docker_registry_image" "this" {
  name          = "${var.app_image}:latest"
  keep_remotely = true
}
