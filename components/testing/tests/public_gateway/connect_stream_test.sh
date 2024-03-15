#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uac_pcap.xml
scenario=$current_dir/../../scenarios/uac_wav_pcap.xml

log_file="uac_pcap_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

sipp -sf $scenario public_gateway:5060 -key username "+855715100850" -s 2222 -m 1 -trace_msg

reset_db

# Assert correct IP in SDP
if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
	exit 1
fi
