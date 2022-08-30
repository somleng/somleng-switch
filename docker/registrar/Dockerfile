FROM debian:bullseye

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg
RUN echo "deb https://apt.opensips.org bullseye ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" >/etc/apt/sources.list.d/opensips.list
RUN apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module opensips-auth-modules

# debug tools (delete me when deploying)
RUN apt-get -y update -qq && apt-get -y install curl tcpdump procps

RUN rm -rf /var/lib/apt/lists/*

COPY opensips.cfg /etc/opensips/opensips.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENV SIP_PORT 5060

EXPOSE 5060/udp

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["opensips"]
