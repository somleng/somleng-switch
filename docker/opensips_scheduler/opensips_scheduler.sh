#!/bin/sh

set -e

while :
do
  if [ -f $FIFO_NAME ]; then
    echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" > $FIFO_NAME
  fi

  sleep 30s
done
