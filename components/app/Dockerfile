ARG RUBY_VERSION=3.3
FROM public.ecr.aws/docker/library/ruby:$RUBY_VERSION-alpine AS build-image

ARG APP_ROOT="/app"
ENV BUNDLE_APP_CONFIG="/app/.bundle"

RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache build-base git pcre-dev openssl-dev && \
    gem install bundler

RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

COPY Gemfile Gemfile.lock $APP_ROOT/

RUN bundle config --local deployment true && \
    bundle config --local path "vendor/bundle" && \
    bundle config --local without 'development test'

RUN bundle install --jobs 20 --retry 5
COPY . .
RUN mkdir -p tmp/pids
RUN rm -rf vendor/bundle/ruby/*/cache/ && find vendor/ -name "*.o" -delete && find vendor/ -name "*.c"


FROM public.ecr.aws/docker/library/ruby:$RUBY_VERSION-alpine

ARG APP_ROOT="/app"
ENV BUNDLE_APP_CONFIG="/app/.bundle"

WORKDIR $APP_ROOT

RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache build-base pcre-dev gcompat && \
    gem install bundler

COPY --from=build-image $APP_ROOT $APP_ROOT

ENV RUBY_YJIT_ENABLE=true

CMD ["bundle", "exec", "ahn", "start", "--no-console"]
