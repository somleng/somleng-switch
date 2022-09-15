variable "instance_type" {
  default = "t3.small"
}

variable "app_identifier" {}
variable "vpc" {}
variable "instance_subnets" {}
variable "cluster_name" {}
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
