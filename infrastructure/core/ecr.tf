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

resource "aws_ecrpublic_repository" "opensips" {
  repository_name = "somleng-switch-opensips"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Switch OpenSIPS"
    architectures     = ["Linux"]

    usage_text = <<EOF
# How to use this image

## Boostrap the Database

### Create a new OpenSIPS database and configures the desired modules

```
  $ docker run --rm -e DATABASE_URL="postgres://postgres:@host.docker.internal:5432/opensips" -e DATABASE_MODULES="dialog load_balancer" public.ecr.aws/somleng/somleng-switch-opensips:bootstrap create_db
```

Replace `DATABASE_URL` with the url of the database you want to use.
Replace `DATABASE_MODULES` with a list of modules you want to use.

### Add a new module

```
  $ docker run --rm -e DATABASE_URL="postgres://postgres:@host.docker.internal:5432/opensips" -e DATABASE_MODULES="dialog load_balancer" public.ecr.aws/somleng/somleng-switch-opensips:bootstrap add_module
```

Replace `DATABASE_URL` with the url of the database you want to use.
Replace `DATABASE_MODULES` with a list of modules you want to add.

## Run OpenSIPS

```
  $ docker run --rm -e DATABASE_URL="postgres://postgres:@host.docker.internal:5432/opensips" public.ecr.aws/somleng/somleng-switch-opensips
```

Replace `DATABASE_URL` with the url of the database you want to use.
Alternatively you set the following environment variables individually:

```
  DATABASE_USERNAME
  DATABASE_PASSWORD
  DATABASE_HOST
  DATABASE_PORT
  DATABASE_NAME
```

You can also set `FIFO_NAME` to override the FIFO location for OpenSIPS. This is useful when using the [scheduler](https://gallery.ecr.aws/somleng/somleng-switch-opensips-scheduler)
EOF
  }
}

resource "aws_ecrpublic_repository" "registrar" {
  repository_name = "somleng-registrar"
  provider = aws.us-east-1

  catalog_data {
    about_text        = "Somleng Registrar"
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

resource "aws_ecr_repository" "services" {
  name = "somleng-switch-services"

  image_scanning_configuration {
    scan_on_push = true
  }
}
