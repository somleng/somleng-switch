#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/register_inbound.xml
source $current_dir/support/test_helpers.sh

reset_db
create_load_balancer_entry "gw" "5060"
create_subscriber_entry "user1" "password" "somleng.org"
reload_opensips_tables

sipp -sf $scenario public_gateway:5060 -s "1234" -key username "user1" -au "user1" -ap "password" -m 1 -trace_msg > /dev/null

reset_db
