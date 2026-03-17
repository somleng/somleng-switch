#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/inbound_forbidden.xml

log_file="inbound_forbidden_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"
public_gateway="$(dig +short public_gateway)"

reset_opensips_db

sipp -sf $scenario public_gateway:5060 -s 1234 -m 1 -trace_msg > /dev/null

reset_opensips_db

if ! assert_in_file "$log_file" "403 Forbidden"; then
	exit 1
fi
