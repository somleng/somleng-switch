variable "ecs_cluster" {}
variable "app_identifier" {}
variable "app_environment" {}
variable "app_image" {}
variable "memory" {}
variable "cpu" {}
variable "aws_region" {}
variable "container_instance_subnets" {}
variable "vpc_id" {}
variable "network_mode" {
  default = "awsvpc"
}
variable "launch_type" {
  default = "FARGATE"
}
variable "ecs_app_autoscale_max_instances" {
  default = 4
}
variable "ecs_app_autoscale_min_instances" {
  default = 1
}
variable "ecs_worker_autoscale_max_instances" {
  default = 4
}
variable "ecs_worker_autoscale_min_instances" {
  default = 1
}
# If the average CPU utilization over a minute drops to this threshold,
# the number of containers will be reduced (but not below ecs_autoscale_min_instances).
variable "ecs_as_cpu_low_threshold_per" {
  default = "20"
}

# If the average CPU utilization over a minute rises to this threshold,
# the number of containers will be increased (but not above ecs_autoscale_max_instances).
variable "ecs_as_cpu_high_threshold_per" {
  default = "80"
}
