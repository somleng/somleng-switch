#!/bin/sh

set -e

echo "Running: $(basename $0)"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/smart_inbound.xml
source $current_dir/support/test_helpers.sh

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -f smart_inbound_*_messages.log
sipp -sf $scenario opensips:5060 -s 1234 -m 1 -trace_msg > /dev/null

reset_db

# Assert correct SDP IP
if ! assert_in_file "smart_inbound_*_messages.log" "c=IN IP4 13.250.230.15"; then
	exit 1
fi

# Assert force_rport is set for NAT
if ! assert_in_file "smart_inbound_*_messages.log" "rport"; then
	exit 1
fi
