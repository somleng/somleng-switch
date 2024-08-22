resource "aws_autoscaling_group" "this" {
  name = var.app_identifier

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  vpc_zone_identifier       = var.instance_subnets
  max_size                  = var.max_capacity
  min_size                  = 0
  desired_capacity          = 0
  wait_for_capacity_timeout = 0
  protect_from_scale_in     = true

  tag {
    key                 = "Name"
    value               = var.app_identifier
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes        = [desired_capacity]
    create_before_destroy = true
  }
}
