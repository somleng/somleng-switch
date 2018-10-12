#!/bin/bash

set -e

if [ "$1" = 'ahn' ]; then
  exec bundle exec ahn start
fi

exec "$@"
