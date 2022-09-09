resource "aws_ecrpublic_repository" "switch" {
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

# TODO Delete this after deploy
resource "aws_ecrpublic_repository" "opensips" {
  repository_name = "somleng-switch-opensips"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch OpenSIPS"
    architectures     = ["Linux"]
  }
}

# Delete this after deploy
resource "aws_ecrpublic_repository" "opensips_scheduler_old" {
  repository_name = "somleng-switch-opensips-scheduler"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch OpenSIPS Scheduler"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "public_gateway" {
  repository_name = "public-gateway"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Public Gateway"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "client_gateway" {
  repository_name = "client-gateway"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Client Gateway"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "media_proxy" {
  repository_name = "media-proxy"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Media Proxy"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "opensips_scheduler" {
  repository_name = "opensips-scheduler"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng OpenSIPS Scheduler"
    architectures     = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "gateway" {
  repository_name = "gateway"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Gateway"
    architectures     = ["Linux"]

    usage_text = <<EOF
  # How to use this image

  ## Boostrap the Database

  ### Create a new OpenSIPS database for the specified gatewaay

  ```
  $ docker run --rm -e PGPASSWORD="password" -e DATABASE_HOST="host.docker.internal" -e DATABASE_USERNAME="postgres" -e DATABASE_PASSWORD="password" -e DATABASE_PORT=5432 -e DATABASE_NAME="opensips_public_gateway" public.ecr.aws/somleng/gateway:bootstrap create_db public_gateway
  $ docker run --rm -e PGPASSWORD="password" -e DATABASE_HOST="host.docker.internal" -e DATABASE_USERNAME="postgres" -e DATABASE_PASSWORD="password" -e DATABASE_PORT=5432 -e DATABASE_NAME="opensips_client_gateway" public.ecr.aws/somleng/gateway:bootstrap create_db client_gateway
  ```

  ### Add a new module

  ```
  $ docker run --rm -e PGPASSWORD="password" -e DATABASE_HOST="host.docker.internal" -e DATABASE_USERNAME="postgres" -e DATABASE_PASSWORD="password" -e DATABASE_PORT=5432 -e DATABASE_NAME="opensips" -e DATABASE_MODULES="rtpproxy" public.ecr.aws/somleng/gateway:bootstrap add_module
  ```
  EOF
  }
}

resource "aws_ecr_repository" "s3_mpeg" {
  name = "s3-mpeg"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "services" {
  name = "somleng-switch-services"

  image_scanning_configuration {
    scan_on_push = true
  }
}
