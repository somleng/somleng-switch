#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/zamtel_sip_options.xml

sipp -sf $scenario public_gateway:5080 -s 1234 -m 1 > /dev/null
