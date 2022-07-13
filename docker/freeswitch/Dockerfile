FROM debian:bullseye

ARG signalwire_token

RUN apt-get update && apt-get install -yq gnupg2 wget lsb-release
RUN wget --http-user=signalwire --http-password=${signalwire_token} -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg

RUN echo "machine freeswitch.signalwire.com login signalwire password ${signalwire_token}" > /etc/apt/auth.conf
RUN echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
RUN echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

RUN apt-get purge -y --auto-remove gnupg2 lsb-release

RUN apt-get update --allow-releaseinfo-change
RUN apt-get -y install libpq-dev libc-dev groff less netcat ffmpeg

# Install FreeSWITCH and required modules
RUN apt-get update && apt-get install -y \
    freeswitch \
    freeswitch-mod-console \
    freeswitch-mod-event-socket \
    freeswitch-mod-logfile \
    freeswitch-mod-rayo \
    freeswitch-mod-sofia \
    freeswitch-mod-dialplan-xml \
    freeswitch-mod-commands \
    freeswitch-mod-dptools \
    freeswitch-mod-http-cache \
    freeswitch-mod-httapi \
    freeswitch-mod-sndfile \
    freeswitch-mod-native-file \
    freeswitch-mod-shout \
    freeswitch-mod-json-cdr \
    freeswitch-mod-flite \
    freeswitch-mod-tone-stream \
    freeswitch-mod-tts-commandline \
    freeswitch-mod-pgsql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install the AWS CLI
RUN apt-get update && apt-get install -y curl unzip && \
    mkdir -p /tmp/aws/ && cd /tmp/aws/ && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    cd / && \
    rm -rf /tmp/aws && \
    apt-get purge -y --auto-remove curl unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
EXPOSE 5080/udp
EXPOSE 5222/tcp

HEALTHCHECK --interval=10s --timeout=5s --retries=10 CMD nc -z -w 5 localhost 5222

ENV FS_CACHE_DIRECTORY "/var/cache"
ENV FS_LOG_DIRECTORY "/var/log/freeswitch"
ENV FS_STORAGE_DIRECTORY "$FS_CACHE_DIRECTORY/freeswitch/storage"
ENV FS_TTS_CACHE_DIRECTORY "$FS_CACHE_DIRECTORY/freeswitch/tts_cache"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch"]
