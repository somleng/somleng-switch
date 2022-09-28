FROM debian:bullseye-slim AS bootstrap

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

# Build

FROM debian:bullseye-slim AS build

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg
RUN echo "deb https://apt.opensips.org bullseye ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" >/etc/apt/sources.list.d/opensips.list
RUN apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module opensips-auth-modules netcat jq

RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["opensips"]

# Public Gateway

FROM build AS public_gateway

COPY public_gateway/opensips.cfg /etc/opensips/opensips.cfg
COPY public_gateway/docker-entrypoint.sh /docker-entrypoint.sh

# Client Gateway

FROM build AS client_gateway

COPY client_gateway/opensips.cfg /etc/opensips/opensips.cfg
COPY client_gateway/docker-entrypoint.sh /docker-entrypoint.sh

