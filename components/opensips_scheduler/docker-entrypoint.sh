#!/bin/sh

set -e

if [ "$1" = 'opensips_scheduler' ]; then
  exec "/usr/local/bin/opensips_scheduler"
fi

exec "$@"
