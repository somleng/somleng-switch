# https://apt.opensips.org/packages.php?os=bookworm

FROM public.ecr.aws/docker/library/debian:bookworm-slim AS bootstrap

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates curl && \
    curl https://apt.opensips.org/opensips-org.gpg -o /usr/share/keyrings/opensips-org.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bookworm ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" >/etc/apt/sources.list.d/opensips.list && \
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bookworm cli-nightly" >/etc/apt/sources.list.d/opensips-cli.list && \
    apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module opensips-cli python3-psycopg2 python3-sqlalchemy python3-sqlalchemy-utils && \
    apt-get purge -y --auto-remove curl && \
    rm -rf /var/lib/apt/lists/*

COPY bootstrap.sh /docker-entrypoint.sh

ENV DATABASE_USERNAME "postgres"
ENV DATABASE_PASSWORD ""
ENV DATABASE_HOST "localhost"
ENV DATABASE_PORT 5432
ENV DATABASE_NAME "opensips"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["create_db"]

# Build

FROM public.ecr.aws/docker/library/debian:bookworm-slim AS build

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates iproute2 curl netcat-traditional jq && \
    curl https://apt.opensips.org/opensips-org.gpg -o /usr/share/keyrings/opensips-org.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bookworm ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" >/etc/apt/sources.list.d/opensips.list && \
    apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module opensips-auth-modules && \
    rm -rf /var/lib/apt/lists/*

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
