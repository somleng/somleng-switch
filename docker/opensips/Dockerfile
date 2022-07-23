FROM debian:bullseye

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG OPENSIPS_VERSION=3.3
ARG OPENSIPS_BUILD=releases

RUN apt-get -y update -qq && apt-get -y install gnupg2 ca-certificates
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg
RUN echo "deb https://apt.opensips.org bullseye ${OPENSIPS_VERSION}-${OPENSIPS_BUILD}" >/etc/apt/sources.list.d/opensips.list
RUN apt-get -y update -qq && apt-get -y install opensips opensips-postgres-module

RUN rm -rf /var/lib/apt/lists/*

COPY opensips.cfg /etc/opensips/opensips.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENV FIFO_NAME "/tmp/opensips_fifo"

EXPOSE 5060/udp
EXPOSE 5080/udp

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["opensips"]
