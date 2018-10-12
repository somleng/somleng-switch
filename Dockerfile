FROM ruby:latest
MAINTAINER dwilkie <dwilkie@gmail.com>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/Gemfile
ADD Gemfile.lock /usr/src/app/Gemfile.lock
RUN bundle install --deployment --without development test
ADD . /usr/src/app

# Install the entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["ahn"]
