FROM debian:stable-slim AS bootstrap

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /tmp

RUN apt-get -y update -qq && apt-get -y install default-mysql-client

RUN rm -rf /var/lib/apt/lists/*

COPY bootstrap/goipinit.sql .
COPY bootstrap/bootstrap.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bootstrap"]

FROM debian:stable-slim

WORKDIR /tmp

RUN apt-get -y update -qq && apt-get -y install libmariadb-dev-compat
RUN ln -s /usr/lib/x86_64-linux-gnu/libmariadb.so.3 /usr/lib/x86_64-linux-gnu/libmysqlclient.so.18

COPY goipcron_x64 /usr/local/bin/goipcron
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["goip"]
