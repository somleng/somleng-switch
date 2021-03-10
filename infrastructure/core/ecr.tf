resource "aws_ecr_repository" "app" {
  name                 = "somleng-adhearsion"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "nginx" {
  name                 = "somleng-adhearsion-nginx"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecrpublic_repository" "app" {
  repository_name = "somleng-adhearsion"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Adhearsion"
    architectures     = ["Linux"]
    description       = "Somleng-Adhearsion is an Adhearsion application compatible with Twilreapi and TwiML. It can be used as a drop-in replacement for Twilio routing calls through local operator, SIP trunk or PBX."
  }
}

resource "aws_ecrpublic_repository" "nginx" {
  repository_name = "somleng-adhearsion-nginx"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Adhearsion Nginx"
    architectures     = ["Linux"]
  }
}

