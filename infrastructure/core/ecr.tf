resource "aws_ecrpublic_repository" "app" {
  repository_name = "somleng-switch"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch"
    architectures     = ["Linux"]
    description       = "Somleng-Switch is an Adhearsion application compatible with Twilreapi and TwiML. It can be used as a drop-in replacement for Twilio routing calls through local operator, SIP trunk or PBX."
  }
}

resource "aws_ecrpublic_repository" "nginx" {
  repository_name = "somleng-switch-nginx"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch Nginx"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "freeswitch" {
  repository_name = "somleng-switch-freeswitch"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch FreeSWITCH"
    architectures     = ["Linux"]
    description       = "FreeSWITCH configuration optimized for Somleng"
  }
}
