#!/bin/sh

set -e

if [ "$1" = 'bootstrap' ]; then
  DATABASE_USERNAME="${DATABASE_USERNAME:="root"}"
  DATABASE_PASSWORD="${DATABASE_PASSWORD:=""}"
  DATABASE_HOST="${DATABASE_HOST:="host.docker.internal"}"
  DATABASE_PORT="${DATABASE_PORT:="3306"}"
  DATABASE_INIT_SCRIPT="${DATABASE_INIT_SCRIPT:="goipinit.sql"}"

  if [ -n "$DATABASE_PASSWORD" ]; then
    mysql -u $DATABASE_USERNAME -p'$DATABASE_PASSWORD' -h $DATABASE_HOST -P $DATABASE_PORT < $DATABASE_INIT_SCRIPT
  else
    mysql -u $DATABASE_USERNAME -h $DATABASE_HOST -P $DATABASE_PORT < $DATABASE_INIT_SCRIPT
  fi
else
  exec "$@"
fi
