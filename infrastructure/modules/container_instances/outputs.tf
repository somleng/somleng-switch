output "autoscaling_group" {
  value = aws_autoscaling_group.this
}

output "ec2_instance_type" {
  value = data.aws_ec2_instance_type.this
}
