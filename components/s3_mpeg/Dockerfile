# syntax=docker/dockerfile:1.7-labs

ARG FUNCTION_DIR="/app"
ARG RUBY_VERSION=3.3
FROM public.ecr.aws/lambda/ruby:$RUBY_VERSION AS build-image

RUN dnf update && \
    dnf -y install openssl-devel gcc make tar xz wget && \
    cd /usr/local/bin/ && \
    wget https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz && \
    tar -xf ffmpeg-master-latest-linuxarm64-gpl.tar.xz && \
    mv ffmpeg-master-latest-linuxarm64-gpl/ ffmpeg/

ARG FUNCTION_DIR
RUN mkdir -p ${FUNCTION_DIR}
COPY Gemfile Gemfile.lock ${FUNCTION_DIR}/
WORKDIR ${FUNCTION_DIR}

ENV BUNDLE_APP_CONFIG="${FUNCTION_DIR}/.bundle"

RUN gem install bundler && \
    bundle config --local deployment true && \
    bundle config --local path "vendor/bundle" && \
    bundle config --local without 'development test' && \
    bundle install

RUN rm -rf vendor/bundle/ruby/*/cache/ && find vendor/ -name "*.o" -delete && find vendor/ -name "*.c"

COPY app.rb ${FUNCTION_DIR}
COPY --exclude=*.key config/ ${FUNCTION_DIR}/config/
COPY lib/ ${FUNCTION_DIR}/lib/

#############################

FROM public.ecr.aws/lambda/ruby:$RUBY_VERSION

ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}

ENV BUNDLE_APP_CONFIG="${FUNCTION_DIR}/.bundle"
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
COPY --from=build-image /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg

RUN ln -s /usr/local/bin/ffmpeg/bin/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/local/bin/ffmpeg/bin/ffprobe /usr/bin/ffprobe

ENV RUBY_YJIT_ENABLE=true

CMD [ "app.App::Handler.process" ]
