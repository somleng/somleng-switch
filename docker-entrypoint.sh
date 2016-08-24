#!/bin/bash

set -e

if [ "$1" = 'ahn' ]; then
  if [ -z "$SECRETS_BUCKET_NAME" ]; then
    echo >&2 'error: missing SECRETS_BUCKET_NAME environment variable'
    exit 1
  fi

  eval $(aws s3 cp s3://${SECRETS_BUCKET_NAME}/${SECRETS_FILE_NAME} - | sed 's/^/export /')

  exec bundle config --global frozen 1 && bundle install --path vendor && bundle exec ahn start
fi

exec "$@"
