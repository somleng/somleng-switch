#!/bin/sh

set -e

if [ "$1" = 'rtpengine' ]; then
  exec "rtpengine"
fi

exec "$@"
