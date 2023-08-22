FROM public.ecr.aws/debian/debian:bookworm-slim

USER root

ENV DEBIAN_FRONTEND noninteractive

ARG REL=latest
ARG DIST=bookworm

WORKDIR /tmp

RUN apt-get -y update -qq && apt-get -y install ca-certificates wget
RUN wget https://dfx.at/rtpengine/latest/pool/main/r/rtpengine-dfx-repo-keyring/rtpengine-dfx-repo-keyring_1.0_all.deb
RUN dpkg -i rtpengine-dfx-repo-keyring_1.0_all.deb
RUN echo "deb [signed-by=/usr/share/keyrings/dfx.at-rtpengine-archive-keyring.gpg] https://dfx.at/rtpengine/$REL $DIST main" | tee /etc/apt/sources.list.d/dfx.at-rtpengine.list
RUN apt-get -y update -qq && apt-get -y install rtpengine netcat-traditional jq curl
RUN apt-get purge -y --auto-remove wget
RUN rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rtpengine"]
