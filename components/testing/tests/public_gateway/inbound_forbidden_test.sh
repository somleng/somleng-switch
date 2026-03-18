#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/inbound_forbidden.xml

media_server="$(dig +short freeswitch)"
public_gateway="$(dig +short public_gateway)"

reset_opensips_db
create_load_balancer_entry "gw" "5060" "2"
create_address_entry "$(hostname -i)" "2"
reload_opensips_tables

clear_sipp_log_file "$scenario"
sipp -sf $scenario public_gateway:5060 -s 4444 -m 1 -trace_msg > /dev/null

reset_opensips_db

log_file=$(find_sipp_log_file $scenario)

if ! assert_in_file "$log_file" "403 Forbidden"; then
	exit 1
fi
