output "autoscaling_group" {
  value = aws_autoscaling_group.this
}

output "ec2_instance_type" {
  value = data.aws_ec2_instance_type.this
}

output "security_group" {
  value = aws_security_group.this
}

output "iam_role" {
  value = data.aws_iam_role.this
}

output "iam_instance_profile" {
  value = local.iam_instance_profile
}
