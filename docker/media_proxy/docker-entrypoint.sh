#!/bin/sh

set -e

if [ "$1" = 'rtpengine' ]; then
  NG_PORT="${NG_PORT:="2223"}"

  if [ -n "$ECS_CONTAINER_METADATA_FILE" ]; then
    LOCAL_IP="$(cat $ECS_CONTAINER_METADATA_FILE | jq -r '.HostPrivateIPv4Address')"
    ADVERTISED_IP="$(cat $ECS_CONTAINER_METADATA_FILE | jq -r '.HostPublicIPv4Address')"
  else
    LOCAL_IP="$(hostname -i)"
    ADVERTISED_IP="${ADVERTISED_IP:="$(hostname -i)"}"
  fi

  eval exec "rtpengine -i $LOCAL_IP!$ADVERTISED_IP -n $ADVERTISED_IP:$NG_PORT -c 127.0.0.1:2224 -f -E -L 7 --config-file=none"
fi

exec "$@"
