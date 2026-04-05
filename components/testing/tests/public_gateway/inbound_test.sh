#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/smart_inbound.xml

media_server="$(dig +short freeswitch)"
public_gateway="$(dig +short public_gateway)"

reset_opensips_db
create_load_balancer_entry "gw" "5060" "2"
create_address_entry "$(hostname -i)" "2"
reload_opensips_tables

cleanup() {
	reset_opensips_db
}

trap cleanup EXIT INT TERM

cdr_server_log="cdr-server.log"
cat /dev/null > $cdr_server_log
clear_sipp_log_file "$scenario"

sipp -sf $scenario public_gateway:5060 -s 1234 -m 1 -trace_msg > /dev/null

log_file=$(find_sipp_log_file $scenario)

if ! assert_in_file $log_file "X-Somleng-CallSid"; then
  exit 1
fi

if ! assert_not_in_file $log_file "X-Somleng-AccountSid"; then
  exit 1
fi

# Assert correct IP in SDP
if ! assert_in_file "$log_file" "c=IN IP4 $media_server"; then
	exit 1
fi

# Assert correct Port in RR
if ! assert_in_file "$log_file" "Record-Route: <sip:$public_gateway:5060"; then
	exit 1
fi

if ! assert_in_file $cdr_server_log "\"record_cdr\": \"true\"" 1; then
  exit 1
fi
