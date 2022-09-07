#!/bin/sh

set -e

while :
do
  if [ -p $FIFO_NAME ]; then
    for mi_command in ${MI_COMMANDS//,/ }
    do
      echo "::{\"jsonrpc\":\"2.0\",\"method\":\"$mi_command\"}" > $FIFO_NAME
    done
  fi

  sleep 30s
done
