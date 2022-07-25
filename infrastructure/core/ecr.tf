resource "aws_ecrpublic_repository" "app" {
  repository_name = "somleng-switch"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch"
    architectures     = ["Linux"]
    description       = "SomlengSWITCH is the switch layer for Somleng. It includes an open source TwiML interpreter"
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

resource "aws_ecrpublic_repository" "freeswitch_event_logger" {
  repository_name = "somleng-switch-freeswitch-event-logger"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch FreeSWITCH Event Logger"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "opensips" {
  repository_name = "somleng-switch-opensips"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch OpenSIPS"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "opensips_scheduler" {
  repository_name = "somleng-switch-opensips-scheduler"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch OpenSIPS Scheduler"
    architectures     = ["Linux"]
  }
}

resource "aws_ecr_repository" "s3_mpeg" {
  name = "s3-mpeg"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ecs_event_runner" {
  name = "ecs-event-runner"

  image_scanning_configuration {
    scan_on_push = true
  }
}

