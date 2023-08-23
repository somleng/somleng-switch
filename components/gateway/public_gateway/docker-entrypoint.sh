#!/bin/sh

set -e

if [ "$1" = 'opensips' ]; then
  OPENSIPS_CONTAINER_BINARY="/usr/sbin/opensips"

  FIFO_NAME="${FIFO_NAME:="/tmp/opensips_fifo"}"
  SIP_PORT="${SIP_PORT:="5060"}"
  SIP_ALTERNATIVE_PORT="${SIP_ALTERNATIVE_PORT:="5080"}"
  DATABASE_URL="${DATABASE_URL:="postgres://postgres:@localhost:5432/opensips"}"
  SIP_ADVERTISED_IP="${SIP_ADVERTISED_IP:="$(hostname -i)"}"
  LOCAL_IP="$(hostname -i)"
  INTERFACE_NAME="$(ip route list | grep default | grep -E  'dev (\w+)' -o | awk '{print $2}')"

  if [ -n "$DATABASE_HOST" ]; then
    DATABASE_URL="postgres://$DATABASE_USERNAME:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"
  fi

  sed -i "s|DATABASE_URL|\"$DATABASE_URL\"|g" /etc/opensips/opensips.cfg
  sed -i "s|FIFO_NAME|\"$FIFO_NAME\"|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_PORT|$SIP_PORT|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_ALTERNATIVE_PORT|$SIP_ALTERNATIVE_PORT|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_ADVERTISED_IP|$SIP_ADVERTISED_IP|g" /etc/opensips/opensips.cfg
  sed -i "s|LOCAL_IP|$LOCAL_IP|g" /etc/opensips/opensips.cfg
  sed -i "s|INTERFACE_NAME|$INTERFACE_NAME|g" /etc/opensips/opensips.cfg

  exec "$OPENSIPS_CONTAINER_BINARY" -FE
fi

exec "$@"
