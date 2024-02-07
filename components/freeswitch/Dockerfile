FROM drachtio/drachtio-freeswitch-base as freeswitch-build

FROM public.ecr.aws/debian/debian:bookworm-slim AS deps-build

RUN apt-get update && apt-get -y --quiet --allow-remove-essential upgrade && \
    apt-get install -y --quiet --no-install-recommends \
    lsof gcc g++ make cmake build-essential git autoconf automake \
    libssl-dev pkg-config ca-certificates

RUN export LD_LIBRARY_PATH=/usr/local/lib:/usr/lib && \
    cd /usr/local/src && \
    git clone https://github.com/warmcat/libwebsockets.git -b v4.3.2 && \
    cd libwebsockets && \
    mkdir -p /usr/local/src/libwebsockets/install/ && \
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo && make && make install

FROM public.ecr.aws/aws-cli/aws-cli as aws-cli

FROM public.ecr.aws/debian/debian:bookworm-slim

ARG signalwire_token

RUN apt-get update && apt-get install --no-install-recommends -yq gnupg2 wget ca-certificates lsb-release && \
    wget --http-user=signalwire --http-password=${signalwire_token} -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg && \
    echo "machine freeswitch.signalwire.com login signalwire password ${signalwire_token}" > /etc/apt/auth.conf && \
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
COPY --link --from=freeswitch-build /usr/local/freeswitch/mod/mod_audio_fork.* /usr/lib/freeswitch/mod/
COPY --link --from=deps-build /usr/local/lib/ /usr/local/lib/
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
ENV MOD_AUDIO_FORK_SUBPROTOCOL_NAME "audio.somleng.org"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch"]
