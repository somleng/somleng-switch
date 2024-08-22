variable "instance_type" {
  default = "t3.small"
}

variable "architecture" {
  default = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "Valid values for var: architecture are (amd64, arm64)."
  }
}

variable "app_identifier" {}
variable "vpc" {}
variable "instance_subnets" {}
variable "cluster_name" {}
variable "iam_instance_profile" {
  default = null
}

variable "max_capacity" {
  default = 10
}
variable "security_groups" {
  default = []
}

variable "associate_public_ip_address" {
  default = false
}

variable "user_data" {
  type = list(
    object(
      {
        path        = string,
        content     = string,
        permissions = string
      }
    )
  )
  default = []
}
