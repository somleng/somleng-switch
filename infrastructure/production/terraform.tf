terraform {
  backend "s3" {
    bucket  = "infrastructure.somleng.org"
    key     = "somleng_switch.tfstate"
    encrypt = true
    region  = "ap-southeast-1"
  }
}

provider "aws" {
  region = var.aws_default_region
}

provider "aws" {
  region = var.aws_helium_region
  alias  = "helium"
}

data "terraform_remote_state" "core" {
  backend = "s3"

  config = {
    bucket = "infrastructure.somleng.org"
    key    = "somleng_switch_core.tfstate"
    region = var.aws_default_region
  }
}

data "terraform_remote_state" "core_infrastructure" {
  backend = "s3"

  config = {
    bucket = "infrastructure.somleng.org"
    key    = "core.tfstate"
    region = var.aws_default_region
  }
}
