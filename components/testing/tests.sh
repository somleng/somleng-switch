#!/bin/sh

# Usage
# /tests.sh [dir]
# Runs tests in the given directory

set -e

echo "Running tests..."

current_dir=$(dirname "$(readlink -f "$0")")
dir=${1:-"$current_dir/tests"}
tests=$(find $dir -type f -name \*.sh)

max_retries=5
for f in $tests; do
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
