#!/bin/sh

set -e

if [ "$1" = 'opensips' ]; then
  OPENSIPS_CONTAINER_BINARY="/usr/sbin/opensips"

  if [ -n "$DATABASE_HOST" ]; then
    DATABASE_URL="postgres://$DATABASE_USERNAME:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"
  fi

  SIP_ADVERTISED_IP="${SIP_ADVERTISED_IP:="$(hostname -i)"}"

  sed -i "s|DATABASE_URL|\"$DATABASE_URL\"|g" /etc/opensips/opensips.cfg
  sed -i "s|FIFO_NAME|\"$FIFO_NAME\"|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_PORT|$SIP_PORT|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_ALTERNATIVE_PORT|$SIP_ALTERNATIVE_PORT|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_ADVERTISED_IP|$SIP_ADVERTISED_IP|g" /etc/opensips/opensips.cfg

  exec "$OPENSIPS_CONTAINER_BINARY" -FE
fi

exec "$@"
