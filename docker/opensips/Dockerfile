# Bootstrap image used to bootstrap OpenSIPS database
#
# Usage:
#
# Initialize a new database:
# docker run --rm -e DATABASE_HOST="host.docker.internal" -e DATABASE_USER="postgres" -e DATABASE_PASSWORD="password" -e DATABASE_PORT=5432 -e DATABASE_NAME="opensips" -e DATABASE_MODULES="dialog load_balancer" public.ecr.aws/somleng/somleng-switch-opensips:bootstrap create_db
#
# Add a database module:
# docker run --rm -e DATABASE_HOST="host.docker.internal" -e DATABASE_USER="postgres" -e DATABASE_PASSWORD="password" -e DATABASE_PORT=5432 -e DATABASE_NAME="opensips" -e DATABASE_MODULES="rtpproxy" public.ecr.aws/somleng/somleng-switch-opensips:bootstrap add_module

FROM debian:bullseye AS bootstrap

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg
RUN echo "deb https://apt.opensips.org bullseye ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" > /etc/apt/sources.list.d/opensips.list
RUN echo "deb https://apt.opensips.org bullseye cli-nightly" > /etc/apt/sources.list.d/opensips-cli.list
RUN apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module opensips-cli python3-psycopg2 m4

RUN rm -rf /var/lib/apt/lists/*

COPY bootstrap.sh /docker-entrypoint.sh

ENV DATABASE_USERNAME "postgres"
ENV DATABASE_PASSWORD ""
ENV DATABASE_HOST "localhost"
ENV DATABASE_PORT 5432
ENV DATABASE_NAME "opensips"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["create_db"]

# Main image

FROM debian:bullseye

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg
RUN echo "deb https://apt.opensips.org bullseye ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" >/etc/apt/sources.list.d/opensips.list
RUN apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module opensips-auth-modules

RUN rm -rf /var/lib/apt/lists/*

COPY opensips.cfg /etc/opensips/opensips.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENV FIFO_NAME "/tmp/opensips_fifo"
ENV DATABASE_URL "postgres://postgres:@localhost:5432/opensips"
ENV SIP_PORT 5060
ENV SIP_ALTERNATIVE_PORT 5080
ENV SIP_ADVERTISED_IP "127.0.0.1"

EXPOSE 5060/udp
EXPOSE 5080/udp

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["opensips"]
