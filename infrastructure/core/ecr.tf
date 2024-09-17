resource "aws_ecrpublic_repository" "public_gateway" {
  repository_name = "public-gateway"
  provider        = aws.us-east-1

  catalog_data {
    about_text    = "Somleng Public Gateway"
    architectures = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "client_gateway" {
  repository_name = "client-gateway"
  provider        = aws.us-east-1

  catalog_data {
    about_text    = "Somleng Client Gateway"
    architectures = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "media_proxy" {
  repository_name = "media-proxy"
  provider        = aws.us-east-1

  catalog_data {
    about_text    = "Somleng Media Proxy"
    architectures = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "opensips_scheduler" {
  repository_name = "opensips-scheduler"
  provider        = aws.us-east-1

  catalog_data {
    about_text    = "Somleng OpenSIPS Scheduler"
    architectures = ["Linux"]
  }
}

resource "aws_ecrpublic_repository" "gateway" {
  repository_name = "gateway"
  provider        = aws.us-east-1

  catalog_data {
    about_text    = "Somleng Gateway"
    architectures = ["Linux"]

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

module "app_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "switch-app"
}

module "webserver_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "switch-webserver"
}

module "freeswitch_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "freeswitch"
}

module "freeswitch_event_logger_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "freeswitch-events"
}

module "s3_mpeg_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "s3-mpeg"
}

module "services_ecr_repository" {
  source = "../modules/ecr_repository"
  name   = "switch-services"
}
