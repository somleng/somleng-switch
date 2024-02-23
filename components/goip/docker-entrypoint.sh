#!/bin/sh

set -e

if [ "$1" = 'goip' ]; then
  GOIP_BINARY="${GOIP_BINARY:="/usr/local/bin/goipcron"}"
  GOIP_CONFIG_FILE="${GOIP_CONFIG_FILE:="/usr/local/bin/inc/config.inc.php"}"
  GOIP_PORT="${GOIP_PORT:="44444"}"

  DATABASE_NAME="${DATABASE_NAME:="goip"}"
  DATABASE_USERNAME="${DATABASE_USERNAME:="root"}"
  DATABASE_PASSWORD="${DATABASE_PASSWORD:=""}"
  DATABASE_HOST="${DATABASE_HOST:="host.docker.internal"}"
  DATABASE_PORT="${DATABASE_PORT:="3306"}"

  mkdir -p "$(dirname $GOIP_CONFIG_FILE)"

  cat <<-EOT > "$GOIP_CONFIG_FILE"
	<?php
	\$dbhost="$DATABASE_HOST";
	\$dbuser="$DATABASE_USERNAME";
	\$dbpw="$DATABASE_PASSWORD";
	\$dbname="$DATABASE_NAME";
	\$goipcronport="$GOIP_PORT";
	\$charset='utf8';
	\$endless_send=0;
	\$re_ask_timer=3;
	?>
	EOT

  exec "$GOIP_BINARY"
else
  exec "$@"
fi
