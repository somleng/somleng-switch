# syntax=docker/dockerfile:1.7-labs

ARG RUBY_VERSION=3.3
FROM public.ecr.aws/lambda/ruby:$RUBY_VERSION AS build-image

RUN dnf update && \
    dnf -y install openssl-devel gcc make tar xz wget && \
    cd /usr/local/bin/ && \
    wget https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz && \
    tar -xf ffmpeg-master-latest-linuxarm64-gpl.tar.xz && \
    mv ffmpeg-master-latest-linuxarm64-gpl/ ffmpeg/

COPY Gemfile Gemfile.lock ${LAMBDA_TASK_ROOT}/

RUN gem install bundler && \
    bundle config --local deployment true && \
    bundle config --local path "vendor/bundle" && \
    bundle config --local without 'development test' && \
    bundle install

RUN rm -rf vendor/bundle/ruby/*/cache/ && find vendor/ -name "*.o" -delete && find vendor/ -name "*.c"

COPY app.rb ${LAMBDA_TASK_ROOT}/
COPY --exclude=*.key config/ ${LAMBDA_TASK_ROOT}/config/

#############################

FROM public.ecr.aws/lambda/ruby:$RUBY_VERSION

COPY --from=build-image ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}
COPY --from=build-image /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg

RUN ln -s /usr/local/bin/ffmpeg/bin/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/local/bin/ffmpeg/bin/ffprobe /usr/bin/ffprobe

ENV RUBY_YJIT_ENABLE=true

CMD [ "app.App::Handler.process" ]
