FROM public.ecr.aws/docker/library/debian:bookworm-slim as freeswitch-build
ARG signalwire_token

RUN apt update && apt install --no-install-recommends -yq cmake gcc g++ make cmake build-essential git libssl-dev libspeex-dev libspeexdsp-dev

RUN apt-get update && apt-get install --no-install-recommends -yq gnupg2 wget ca-certificates lsb-release && \
    wget --http-user=signalwire --http-password=${signalwire_token} -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg && \
    echo "machine freeswitch.signalwire.com login signalwire password ${signalwire_token}" > /etc/apt/auth.conf && \
    chmod 600 /etc/apt/auth.conf && \
    echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list && \
    echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list && \
    apt-get update --allow-releaseinfo-change && \
    apt-get -y install --no-install-recommends libfreeswitch-dev

COPY src/mod/mod_twilio_stream /usr/src/mod_twilio_stream

RUN  mkdir -p /usr/src/mod_twilio_stream/build
WORKDIR /usr/src/mod_twilio_stream/build
RUN cmake ..
RUN make
RUN make install

FROM public.ecr.aws/aws-cli/aws-cli as aws-cli

FROM public.ecr.aws/docker/library/debian:bookworm-slim

ARG signalwire_token

RUN apt-get update && apt-get install --no-install-recommends -yq libssl-dev libspeex-dev libspeexdsp-dev gnupg2 wget ca-certificates lsb-release && \
    wget --http-user=signalwire --http-password=${signalwire_token} -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg && \
    echo "machine freeswitch.signalwire.com login signalwire password ${signalwire_token}" > /etc/apt/auth.conf && \
    chmod 600 /etc/apt/auth.conf && \
    echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list && \
    echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list && \
    apt-get update --allow-releaseinfo-change && \
    apt-get -y install --no-install-recommends netcat-traditional ffmpeg \
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
            freeswitch-mod-tts-commandline && \
            apt-get purge -y --auto-remove wget gnupg2 lsb-release \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/*

# Copy the Freeswitch configuration
COPY --link conf/ /etc/freeswitch

# Copy Bin Files
COPY --link bin/ /usr/local/bin/

RUN chown -R freeswitch:daemon /etc/freeswitch && \
    touch /var/log/freeswitch/freeswitch.log && \
    chown freeswitch:freeswitch /var/log/freeswitch/freeswitch.log

COPY --link --from=aws-cli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --link --from=aws-cli /usr/local/bin/ /usr/local/bin
COPY --link --from=freeswitch-build /usr/local/freeswitch/mod/mod_twilio_stream.so /usr/lib/freeswitch/mod/

RUN ldconfig

# Install the entrypoint script
COPY --link docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 5060/udp
EXPOSE 5080/udp
EXPOSE 5222/tcp
EXPOSE 8021/tcp

HEALTHCHECK --interval=10s --timeout=5s --retries=10 CMD nc -z -w 5 localhost 5222

ENV FS_CACHE_DIRECTORY "/var/cache"
ENV FS_LOG_DIRECTORY "/var/log/freeswitch"
ENV FS_STORAGE_DIRECTORY "$FS_CACHE_DIRECTORY/freeswitch/storage"
ENV FS_TTS_CACHE_DIRECTORY "$FS_CACHE_DIRECTORY/freeswitch/tts_cache"
ENV MOD_TWILIO_STREAM_SUBPROTOCOL_NAME "audio.somleng.org"
ENV MOD_TWILIO_STREAM_MIN_BUFFER_MILISECS "500"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch"]
