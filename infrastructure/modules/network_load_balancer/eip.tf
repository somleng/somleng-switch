resource "aws_eip" "this" {
  count  = length(var.vpc.public_subnets)
  domain = "vpc"

  tags = {
    Name = var.identifier
  }
}
