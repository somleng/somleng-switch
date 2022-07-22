ARG FUNCTION_DIR="/app"

FROM ruby:3.1-alpine as build-image

RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache build-base postgresql-dev

RUN gem install bundler

ARG FUNCTION_DIR
RUN mkdir -p ${FUNCTION_DIR}
COPY Gemfile Gemfile.lock ${FUNCTION_DIR}/
WORKDIR ${FUNCTION_DIR}

ENV BUNDLE_APP_CONFIG="${FUNCTION_DIR}/.bundle"

RUN bundle config --local deployment true && \
    bundle config --local path "vendor/bundle" && \
    bundle config --local without 'development test'

RUN bundle install --jobs 20 --retry 5

RUN rm -rf vendor/bundle/ruby/*/cache/ && find vendor/ -name "*.o" -delete && find vendor/ -name "*.c"

COPY app.rb ${FUNCTION_DIR}
COPY app/ ${FUNCTION_DIR}

#############################

FROM ruby:3.1-alpine

ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}

ENV BUNDLE_APP_CONFIG="${FUNCTION_DIR}/.bundle"
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache postgresql-dev && \
    gem install bundler && \
    gem install aws_lambda_ric

ENTRYPOINT [ "/usr/local/bundle/bin/aws_lambda_ric" ]
CMD [ "app.App::Handler.process" ]
