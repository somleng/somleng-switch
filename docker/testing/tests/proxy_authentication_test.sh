#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/proxy_authentication.xml
source $current_dir/support/test_helpers.sh

reset_db

sipp -sf $scenario public_gateway:5060 -s 1234 -m 1 > /dev/null
