variable "aws_region" {
  default = "ap-southeast-1"
}

locals {
  region = data.terraform_remote_state.core_infrastructure.outputs.hydrogen_region
}
