#!/bin/sh

set -e

if [ "$1" = 'rtpengine' ]; then
  NG_PORT="${NG_PORT:="2223"}"
  HEALTHCHECK_PORT="${HEALTH_CHECK_PORT:="25060"}"

  LOG_LEVEL="${LOG_LEVEL:="6"}"

  if [ -n "$ECS_CONTAINER_METADATA_FILE" ]; then
    LOCAL_IP="$(cat $ECS_CONTAINER_METADATA_FILE | jq -r '.HostPrivateIPv4Address')"
    ADVERTISED_IP="$(cat $ECS_CONTAINER_METADATA_FILE | jq -r '.HostPublicIPv4Address')"
  else
    LOCAL_IP="$(hostname -i)"
    ADVERTISED_IP="${ADVERTISED_IP:="$(hostname -i)"}"
  fi

  eval exec "rtpengine --interface=$LOCAL_IP!$ADVERTISED_IP --listen-ng=$LOCAL_IP:$NG_PORT --listen-tcp-ng=$LOCAL_IP:$HEALTH_CHECK_PORT --listen-cli=127.0.0.1:2224 --foreground --log-stderr --log-level=$LOG_LEVEL --config-file=none"
fi

exec "$@"
