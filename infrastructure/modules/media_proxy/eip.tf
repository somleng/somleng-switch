resource "aws_eip" "media_proxy" {
  count  = var.assign_eips ? var.max_tasks : 0
  domain = "vpc"

  tags = {
    Name             = "Media Proxy ${count.index + 1}"
    (var.identifier) = "true"
    Priority         = count.index + 1
  }
}
