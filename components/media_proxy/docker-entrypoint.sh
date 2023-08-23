#!/bin/sh

set -e

if [ "$1" = 'rtpengine' ]; then
  NG_PORT="${NG_PORT:="2223"}"
  HEALTHCHECK_PORT="${HEALTHCHECK_PORT:="2224"}"
  MEDIA_PORT_MIN="${MEDIA_PORT_MIN:="30000"}"
  MEDIA_PORT_MAX="${MEDIA_PORT_MAX:="40000"}"

  LOG_LEVEL="${LOG_LEVEL:="6"}"

  LOCAL_IP="$(hostname -i)"

  if [ -n "$ECS_CONTAINER_METADATA_FILE" ]; then
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    AWS_PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
    ADVERTISED_IP="${ADVERTISED_IP:="$AWS_PUBLIC_IP"}"
  else
    ADVERTISED_IP="${ADVERTISED_IP:="$(hostname -i)"}"
  fi

  eval exec "rtpengine --interface=$LOCAL_IP!$ADVERTISED_IP --listen-ng=$LOCAL_IP:$NG_PORT --listen-cli=$LOCAL_IP:$HEALTHCHECK_PORT --foreground --log-stderr --log-level=$LOG_LEVEL --port-min=$MEDIA_PORT_MIN --port-max=$MEDIA_PORT_MAX --config-file=none"
fi

exec "$@"
