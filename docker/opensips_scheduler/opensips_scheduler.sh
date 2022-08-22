#!/bin/sh

set -e

while :
do
  if [ -p $FIFO_NAME ]; then
    echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" > $FIFO_NAME
    echo "::{\"jsonrpc\":\"2.0\",\"method\":\"address_reload\"}" > $FIFO_NAME
  fi

  sleep 30s
done
