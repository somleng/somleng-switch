#!/bin/sh

# Usage
# Runs tests in the tests directory relative to this script.

set -e

echo "Running tests..."

current_dir=$(dirname "$(readlink -f "$0")")

for f in $current_dir/tests/*.sh; do
  sh "$f"
done
