FROM debian:bullseye-slim

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates jq
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg
RUN echo "deb https://apt.opensips.org bullseye ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" >/etc/apt/sources.list.d/opensips.list
RUN apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module opensips-auth-modules netcat
RUN rm -rf /var/lib/apt/lists/*

COPY opensips.cfg /etc/opensips/opensips.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["opensips"]
