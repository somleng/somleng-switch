#!/bin/sh

set -e

if [ "$1" = 'opensips_scheduler' ]; then
  while :
  do
    echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" > $FIFO_NAME
    sleep 30s
  done
fi

exec "$@"
