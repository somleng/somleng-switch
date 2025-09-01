#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/zamtel_inbound.xml

log_file="zamtel_inbound_*_messages.log"
rm -f $log_file

reset_opensips_db
create_load_balancer_entry "gwalt" "5080"
create_address_entry $(hostname -i)
reload_opensips_tables

public_gateway="$(dig +short public_gateway)"

sipp -sf $scenario public_gateway:5080 -s 7888 -m 1 -trace_msg > /dev/null
reset_opensips_db

# Assert correct IP in SDP
if ! assert_in_file "$log_file" "c=IN IP4 18.141.245.230"; then
	exit 1
fi

# Assert correct Port in RR
if ! assert_in_file "$log_file" "Record-Route: <sip:$public_gateway:5080"; then
	exit 1
fi
