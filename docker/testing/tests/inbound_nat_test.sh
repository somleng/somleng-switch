#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/inbound_nat.xml
source $current_dir/support/test_helpers.sh

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -f inbound_nat_*_messages.log
sipp -sf $scenario public_gateway:5060 -s 1234 -m 1 -trace_msg > /dev/null

reset_db

# Assert force_rport is set
if ! assert_in_file "inbound_nat_*_messages.log" "rport"; then
	exit 1
fi
