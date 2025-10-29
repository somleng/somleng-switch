#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/inbound_double_record_routes.xml

reset_opensips_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -f inbound_double_record_routes_*_messages.log
sipp -sf $scenario public_gateway:5060 -s 1111 -m 1 -trace_msg > /dev/null

reset_opensips_db

if ! assert_in_file "inbound_double_record_routes_*_messages.log" "r2=on"; then
	exit 1
fi
