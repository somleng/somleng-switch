#!/bin/sh

set -e

if [ "$1" = 'opensips' ]; then
  OPENSIPS_CONTAINER_BINARY="/usr/sbin/opensips"

  FIFO_NAME="${FIFO_NAME:="/tmp/opensips_fifo"}"
  DATABASE_URL="${DATABASE_URL:="postgres://postgres:@localhost:5432/opensips"}"
  SIP_PORT="${SIP_PORT:="5060"}"

  if [ -n "$DATABASE_HOST" ]; then
    DATABASE_URL="postgres://$DATABASE_USERNAME:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"
  fi

  LOCAL_IP="$(hostname -i)"

  if [ -n "$ECS_CONTAINER_METADATA_FILE" ]; then
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    AWS_PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
    SIP_ADVERTISED_IP="${SIP_ADVERTISED_IP:="$AWS_PUBLIC_IP"}"
  else
    SIP_ADVERTISED_IP="${SIP_ADVERTISED_IP:="$(hostname -i)"}"
  fi

  sed -i "s|FIFO_NAME|\"$FIFO_NAME\"|g" /etc/opensips/opensips.cfg
  sed -i "s|DATABASE_URL|\"$DATABASE_URL\"|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_PORT|$SIP_PORT|g" /etc/opensips/opensips.cfg
  sed -i "s|SIP_ADVERTISED_IP|$SIP_ADVERTISED_IP|g" /etc/opensips/opensips.cfg
  sed -i "s|LOCAL_IP|$LOCAL_IP|g" /etc/opensips/opensips.cfg

  exec "$OPENSIPS_CONTAINER_BINARY" -FE
fi

exec "$@"
