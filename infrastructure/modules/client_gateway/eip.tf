resource "aws_eip" "client_gateway" {
  count  = var.assign_eips ? var.max_tasks : 0
  domain = "vpc"

  tags = {
    Name             = "${var.identifier} ${count.index + 1}"
    (var.identifier) = "true"
    Priority         = count.index + 1
  }
}
