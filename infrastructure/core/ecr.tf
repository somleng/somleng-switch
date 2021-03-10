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

