FROM debian:buster

# make the "en_US.UTF-8" locale so freeswitch will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.utf8

RUN apt-get update && apt-get install -y curl gnupg2 lsb-release \
    && curl https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add - \
    && echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list \
    && echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list \
    && apt-get purge -y --auto-remove curl gnupg2 lsb-release

RUN apt-get update && apt-get install -y freeswitch
RUN apt-get update --allow-releaseinfo-change && apt-get -y install libpq-dev libc-dev groff less netcat mpg123

# Install the AWS CLI
RUN apt-get -y install curl unzip && \
    mkdir -p /tmp/aws/ && cd /tmp/aws/ && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    cd / && \
    rm -rf /tmp/aws && \
    apt-get purge -y --auto-remove curl unzip

# Install required freeswitch modules
RUN apt-get update && apt-get install -y freeswitch-mod-console freeswitch-mod-logfile freeswitch-mod-rayo freeswitch-mod-sofia freeswitch-mod-dialplan-xml freeswitch-mod-commands freeswitch-mod-dptools freeswitch-mod-http-cache freeswitch-mod-httapi freeswitch-mod-sndfile freeswitch-mod-native-file freeswitch-mod-shout freeswitch-mod-json-cdr freeswitch-mod-flite freeswitch-mod-tone-stream freeswitch-mod-tts-commandline freeswitch-mod-pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the Freeswitch configuration
COPY conf /etc/freeswitch

# Copy Bin Files
COPY bin/ /usr/local/bin/

RUN chown -R freeswitch:daemon /etc/freeswitch

RUN touch /var/log/freeswitch/freeswitch.log
RUN chown freeswitch:freeswitch /var/log/freeswitch/freeswitch.log

# Install the entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 5060/udp
EXPOSE 5222/tcp

HEALTHCHECK --interval=10s --timeout=5s --retries=10 CMD nc -z -w 5 localhost 5222

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch"]
