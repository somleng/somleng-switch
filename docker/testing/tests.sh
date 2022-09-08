#!/bin/sh

# Usage
# Runs tests in the tests directory relative to this script.

set -e

echo "Running tests..."

current_dir=$(dirname "$(readlink -f "$0")")

max_retries=5

tests_dir="$1"

for f in $current_dir/tests/$tests_dir/*.sh; do
  i=0
  while [ "$i" -lt $max_retries ]
  do
    i=$((i+1))
    echo "Running $(basename $f): Attempt $i of $max_retries"
    sh "$f" && break
    sleep 5
  done

  [ "$i" -eq $max_retries ] && exit 1
done

exit 0
