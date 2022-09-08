#!/bin/sh

# Usage
# Runs tests in the tests directory relative to this script.

set -e

echo "Running tests..."

current_dir=$(dirname "$(readlink -f "$0")")

tag="$1"
database_url="${DATABASE_URL:="postgres://$DATABASE_USERNAME:@$DATABASE_HOST:$DATABASE_PORT/opensips_${tag}_test"}"
fifo_name="${FIFO_NAME:="$FIFO_DIR/$tag"}"

max_retries=5

for f in $current_dir/tests/$tag/*.sh; do
  i=0
  while [ "$i" -lt $max_retries ]
  do
    i=$((i+1))
    echo "Running $(basename $f): Attempt $i of $max_retries"
    DATABASE_URL=$database_url FIFO_NAME=$fifo_name sh "$f" && break
    sleep 5
  done

  [ "$i" -eq $max_retries ] && exit 1
done

exit 0
