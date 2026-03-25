resource "aws_security_group" "this" {
  name   = local.security_group_name
  vpc_id = var.vpc.vpc_id
  ingress {
    from_port   = "6379"
    to_port     = "6379"
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Name = local.security_group_name
  }
}
