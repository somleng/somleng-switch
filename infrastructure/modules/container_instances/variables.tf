variable "instance_type" {
  default = "t3.small"
}

variable "app_identifier" {}
variable "vpc" {}
variable "instance_subnets" {}
variable "cluster_name" {}

variable "max_capacity" {
  default = 10
}
variable "security_groups" {
  default = []
}

variable "user_data" {
  type = list(
    object(
      {
        path = string,
        content = string,
        permissions = string
      }
    )
  )
  default = []
}
