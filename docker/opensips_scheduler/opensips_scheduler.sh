#!/bin/sh

set -e

while :
do
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" > $FIFO_NAME
  sleep 30s
done
