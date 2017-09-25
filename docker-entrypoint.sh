#!/bin/bash

set -e

if [ "$1" = 'ahn' ]; then
  if [ -n "$ADHEARSION_CONFIG_S3_PATH" ]; then
    # Pull Adhearsion configuration from S3
    eval $(aws s3 cp ${ADHEARSION_CONFIG_S3_PATH} - | sed 's/^/export /')
  fi

  exec bundle exec ahn start
fi

exec "$@"
