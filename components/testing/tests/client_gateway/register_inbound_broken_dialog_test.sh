#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/register_inbound_broken_dialog.xml

reset_db

client_gateway="$(dig +short client_gateway)"
create_domain_entry "$client_gateway"
create_load_balancer_entry "gw" "5060"
create_subscriber_entry "user1" "password" "somleng.org"
create_rtpengine_entry "udp:media_proxy:2223"
reload_opensips_tables

sipp -sf $scenario client_gateway:5060 -s "1234" -key username "user1" -au "user1" -ap "password" -m 1 -trace_msg > /dev/null

reset_db
