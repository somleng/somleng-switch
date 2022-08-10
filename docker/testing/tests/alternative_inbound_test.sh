#!/bin/sh

set -e

echo "Running: $(basename $0)"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/zamtel_inbound.xml
source $current_dir/support/test_helpers.sh

reset_db
create_load_balancer_entry "gwalt" "5080"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -f zamtel_inbound_*_messages.log
sipp -sf $scenario opensips:5080 -s 7888 -m 1 -trace_msg > /dev/null
reset_db

if ! assert_in_file "zamtel_inbound_*_messages.log" "c=IN IP4 18.141.245.230"; then
	exit 1
fi
