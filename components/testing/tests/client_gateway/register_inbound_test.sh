#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/register_inbound.xml

log_file="register_inbound_*_messages.log"
rm -f $log_file

reset_db

uac=$(hostname -i)
client_gateway="$(dig +short client_gateway)"
media_proxy="$(dig +short media_proxy)"

create_domain_entry "$client_gateway"
create_load_balancer_entry "gw" "5060"
create_subscriber_entry "user1" "password" "somleng.org"
create_rtpengine_entry "udp:media_proxy:2223"
reload_opensips_tables

sipp -sf $scenario client_gateway:5060 -s "1234" -key username "user1" -key contact_ip "$uac" -au "user1" -ap "password" -m 1 -trace_msg > /dev/null

reset_db

if ! assert_in_file $log_file "Record-Route: <sip:$client_gateway:5060;lr;r2=on>"; then
  exit 1
fi

if ! assert_in_file $log_file "c=IN IP4 $media_proxy"; then
  exit 1
fi
