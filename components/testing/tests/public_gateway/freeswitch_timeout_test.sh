#!/bin/sh

# This test simulates what happens if FreeSWITCH does not reply with a 200 OK after load balancing
# It creates a load balancer entry to the the a SIPp server running on port 5061 which simulates
# the timeout by not sending a 200 OK response to the gateway before the timeout period.
# The gateway then sends a Cancel request to the SIPp server and returns a 500 to the UAC.
# This test is useful to test the behavior of the gateway when this scenario happens.

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/gateway_down.xml
freeswitch_uas_scenario=$current_dir/../../scenarios/freeswitch_timeout.xml

log_file="gateway_down_*_messages.log"
rm -f $log_file

public_gateway="$(dig +short public_gateway)"

reset_opensips_db
create_load_balancer_entry "gw" "5061" "1" "$(hostname -i)"
create_address_entry "$(hostname -i)" "1"
reload_opensips_tables

nohup sipp -sf $freeswitch_uas_scenario -p 5061 -aa -trace_msg -trace_err &
sipp_server_pid=$!

sipp -sf $scenario public_gateway:5060 -s 1234 -m 1 -trace_msg -trace_err > /dev/null

kill $sipp_server_pid

reset_opensips_db

# Assert 500 All GW are down is returned to the UAC.
if ! assert_in_file "$log_file" "All GW are down"; then
	exit 1
fi
