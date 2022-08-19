#!/bin/sh

set -e

exit 0

echo "Running: $(basename $0)"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/forbidden.xml
source $current_dir/support/test_helpers.sh

reset_db

sipp -sf $scenario opensips:5060 -s 1234 -m 1 > /dev/null
