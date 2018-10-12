#!/bin/bash

set -e

if [ "$1" = 'ahn' ]; then
  export AHN_ADHEARSION_DRB_HOST="$HOSTNAME"
  exec bundle exec ahn start
fi

exec "$@"
