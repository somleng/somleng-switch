#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/smart_inbound.xml

log_file="smart_inbound_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"
public_gateway="$(dig +short public_gateway)"

reset_opensips_db
create_load_balancer_entry "gw" "5060" "2"
create_address_entry "$(hostname -i)" "2"
reload_opensips_tables

sipp -sf $scenario public_gateway:5060 -s 1234 -m 1 -trace_msg > /dev/null

reset_opensips_db

# Assert correct IP in SDP
if ! assert_in_file "$log_file" "c=IN IP4 $media_server"; then
	exit 1
fi

# Assert correct Port in RR
if ! assert_in_file "$log_file" "Record-Route: <sip:$public_gateway:5060"; then
	exit 1
fi
